#!/usr/bin/env python3
"""Validate approved masters or a complete level 1-100 runtime export."""

from __future__ import annotations

import argparse
import json
import struct
import sys
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
MANIFEST = Path(__file__).with_name("pipeline_manifest.json")


def _arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--masters-only", action="store_true")
    return parser.parse_args()


def _inspect(path: Path, expected_size: tuple[int, int] | None = None) -> list[str]:
    errors: list[str] = []
    if not path.is_file():
        return [f"missing: {path.relative_to(ROOT)}"]
    raw = path.read_bytes()
    if len(raw) < 26 or raw[:8] != b"\x89PNG\r\n\x1a\n":
        return [f"not PNG: {path.relative_to(ROOT)}"]
    width, height = struct.unpack(">II", raw[16:24])
    if raw[25] != 6:
        errors.append(f"not 32-bit RGBA: {path.relative_to(ROOT)}")
    with Image.open(path) as image:
        rgba = image.convert("RGBA")
        if expected_size is not None and rgba.size != expected_size:
            errors.append(
                f"wrong canvas {rgba.size}, expected {expected_size}: "
                f"{path.relative_to(ROOT)}"
            )
        corners = (
            rgba.getpixel((0, 0))[3],
            rgba.getpixel((width - 1, 0))[3],
            rgba.getpixel((0, height - 1))[3],
            rgba.getpixel((width - 1, height - 1))[3],
        )
        if corners != (0, 0, 0, 0):
            errors.append(f"opaque corner: {path.relative_to(ROOT)} {corners}")
    return errors


def _stage_paths(identity: str, stage: int) -> tuple[Path, Path]:
    token = f"{stage:02d}"
    root = ROOT / "assets/characters" / identity
    return root / f"level_{token}.png", root / f"level_{token}_back.png"


def main() -> int:
    args = _arguments()
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    errors: list[str] = []
    for identity, definition in manifest["identities"].items():
        front = ROOT / definition["front_master"]
        back = ROOT / definition["back_master"]
        errors.extend(_inspect(front))
        errors.extend(_inspect(back))
        if front.is_file() and back.is_file():
            with Image.open(front) as front_image, Image.open(back) as back_image:
                width_delta = abs(front_image.width - back_image.width) / front_image.width
                height_delta = abs(front_image.height - back_image.height) / front_image.height
                if width_delta >= 0.03 or height_delta >= 0.03:
                    errors.append(f"front/back canvas drift exceeds 3%: {identity}")

    if not args.masters_only:
        canvas = (manifest["canvas"]["width"], manifest["canvas"]["height"])
        for stage in manifest["stages"]:
            for identity in manifest["identities"]:
                for path in _stage_paths(identity, stage):
                    errors.extend(_inspect(path, canvas))

    if errors:
        print("Character pipeline validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    scope = "approved masters" if args.masters_only else "complete release export"
    print(f"Validated {scope} for {len(manifest['identities'])} identities.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
