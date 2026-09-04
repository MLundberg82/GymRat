#!/usr/bin/env python3
"""Generate deterministic breathing frames from approved GymRat masters.

This tool never invents or redraws a character. It applies a small, smooth
torso deformation to the exact approved RGBA pixels and keeps the original
canvas, foot line, identity, outfit, lighting, and transparent background.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
CHARACTERS = ROOT / "assets" / "characters"
FRAME_POWERS = (0.0, 0.25, 0.5, 0.75, 1.0)


@dataclass(frozen=True)
class CharacterMaster:
    identity: str
    view: str
    source: Path

    @property
    def output_dir(self) -> Path:
        return CHARACTERS / self.identity / "motion" / "level_01" / self.view


MASTERS = tuple(
    CharacterMaster(
        identity=identity,
        view=view,
        source=CHARACTERS
        / identity
        / ("level_01.png" if view == "front" else "level_01_back.png"),
    )
    for identity in ("male", "female", "non_binary")
    for view in ("front", "back")
)


def _torso_center(alpha: np.ndarray) -> float:
    """Find the body center without letting the tail skew the anchor."""
    height, width = alpha.shape
    centers: list[float] = []
    for y in range(round(height * 0.22), round(height * 0.48)):
        foreground = np.flatnonzero(alpha[y] >= 0.2)
        if foreground.size >= width * 0.08:
            lower = np.quantile(foreground, 0.15)
            upper = np.quantile(foreground, 0.85)
            centers.append(float((lower + upper) / 2))
    return float(np.median(centers)) if centers else (width - 1) / 2


def _bilinear_sample(image: np.ndarray, source_x: np.ndarray) -> np.ndarray:
    height, width, channels = image.shape
    target_y = np.arange(height, dtype=np.float32)[:, None]
    x0 = np.floor(source_x).astype(np.int32)
    x1 = np.clip(x0 + 1, 0, width - 1)
    x0 = np.clip(x0, 0, width - 1)
    fraction = (source_x - x0)[..., None]
    rows = np.broadcast_to(np.arange(height)[:, None], (height, width))
    left = image[rows, x0]
    right = image[rows, x1]
    sampled = left * (1.0 - fraction) + right * fraction
    assert sampled.shape == (height, width, channels)
    return sampled


def _breathing_frame(source: Image.Image, power: float) -> Image.Image:
    rgba = np.asarray(source.convert("RGBA"), dtype=np.float32) / 255.0
    alpha = rgba[..., 3]

    # Interpolate premultiplied color so semi-transparent fur and whisker edges
    # cannot acquire black, white, or checkerboard-colored fringes.
    premultiplied = rgba.copy()
    premultiplied[..., :3] *= alpha[..., None]

    height, width = alpha.shape
    center_x = _torso_center(alpha)
    y = np.arange(height, dtype=np.float32)[:, None]
    x = np.arange(width, dtype=np.float32)[None, :]

    top = height * 0.185
    bottom = height * 0.515
    progress = np.clip((y - top) / (bottom - top), 0.0, 1.0)
    envelope = np.maximum(np.sin(progress * np.pi), 0.0) ** 1.7
    envelope *= ((y >= top) & (y <= bottom)).astype(np.float32)

    # Peak inhale widens the ribcage by 1.35%. The deformation tapers to zero
    # before the head and waistband, so the face and foot line remain fixed.
    expansion = 1.0 + envelope * (0.0135 * power)
    source_x = center_x + (x - center_x) / expansion
    source_x = np.broadcast_to(source_x, (height, width))

    sampled = _bilinear_sample(premultiplied, source_x)
    sampled_alpha = np.clip(sampled[..., 3], 0.0, 1.0)
    output = np.zeros_like(sampled)
    visible = sampled_alpha > (0.5 / 255.0)
    output[..., 3] = sampled_alpha
    output[..., :3][visible] = (
        sampled[..., :3][visible] / sampled_alpha[visible, None]
    )
    output = np.clip(np.rint(output * 255.0), 0, 255).astype(np.uint8)

    # Transparent RGB is deliberately zeroed and every canvas corner is
    # guaranteed alpha 0 for predictable Flutter compositing.
    output[output[..., 3] == 0, :3] = 0
    for corner_y, corner_x in (
        (0, 0),
        (0, width - 1),
        (height - 1, 0),
        (height - 1, width - 1),
    ):
        output[corner_y, corner_x] = 0

    return Image.fromarray(output, mode="RGBA")


def main() -> None:
    for master in MASTERS:
        source = Image.open(master.source).convert("RGBA")
        master.output_dir.mkdir(parents=True, exist_ok=True)
        for index, power in enumerate(FRAME_POWERS):
            output = master.output_dir / f"breath_{index:02d}.png"
            _breathing_frame(source, power).save(
                output,
                format="PNG",
                optimize=True,
                compress_level=9,
            )
            print(output.relative_to(ROOT))


if __name__ == "__main__":
    main()
