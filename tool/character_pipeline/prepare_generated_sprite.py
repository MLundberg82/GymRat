#!/usr/bin/env python3
"""Turn generated GymRat art into deterministic, transparent app sprites.

The generator can return a baked transparency checker. This tool removes only
that neutral bright background, isolates full connected characters, and places
them on the canonical 1024x1792 canvas with a shared scale and foot line.
"""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image


CANVAS = (1024, 1792)
TOP_MARGIN = 54
# Poses such as double biceps are intentionally wider than the neutral stance.
# Keep enough transparent padding for filtering without shrinking the whole rat
# vertically just to preserve the neutral pose's larger side gutter.
SIDE_MARGIN = 32
BOTTOM_MARGIN = 48


def _arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--output", type=Path)
    group.add_argument("--sheet-output-dir", type=Path)
    return parser.parse_args()


def _rgba_without_checker(path: Path) -> np.ndarray:
    image = Image.open(path).convert("RGBA")
    rgba = np.asarray(image, dtype=np.uint8).copy()
    source_had_alpha = image.getextrema()[3] != (255, 255)
    if source_had_alpha:
        rgba[rgba[..., 3] == 0, :3] = 0
        return rgba

    rgb = rgba[..., :3].astype(np.int16)
    blue_dominance = rgb[..., 2] - np.maximum(rgb[..., 0], rgb[..., 1])
    border = np.concatenate(
        (
            blue_dominance[:16].reshape(-1),
            blue_dominance[-16:].reshape(-1),
            blue_dominance[:, :16].reshape(-1),
            blue_dominance[:, -16:].reshape(-1),
        )
    )
    if np.percentile(border, 50) >= 180:
        # Image generators often paint a checkerboard instead of exporting
        # alpha. A deliberately blue-screened review render gives us a much
        # cleaner deterministic matte, including fur and whisker edges. The
        # two thresholds retain opaque subject pixels, feather mixed edge
        # pixels, and reject the uniform blue field.
        border_rgb = np.concatenate(
            (
                rgb[:16].reshape(-1, 3),
                rgb[-16:].reshape(-1, 3),
                rgb[:, :16].reshape(-1, 3),
                rgb[:, -16:].reshape(-1, 3),
            )
        )
        background_rgb = np.median(border_rgb, axis=0).astype(np.float32)
        background_dominance = max(
            1.0,
            background_rgb[2] - max(background_rgb[0], background_rgb[1]),
        )
        alpha = np.clip(
            1.0
            - np.maximum(blue_dominance.astype(np.float32), 0.0)
            / background_dominance,
            0.0,
            1.0,
        )
        alpha[blue_dominance <= 0] = 1.0
        alpha[blue_dominance >= background_dominance * 0.94] = 0.0

        # Undo the blue-screen contribution in straight-alpha space. This is
        # what removes the thin blue fringe that a simple colour threshold
        # leaves around fur, whiskers and claws.
        mixed = (alpha > 0.03) & (alpha < 1.0)
        for channel in range(3):
            foreground = (
                rgb[..., channel].astype(np.float32)
                - (1.0 - alpha) * background_rgb[channel]
            ) / np.maximum(alpha, 0.03)
            rgba[..., channel][mixed] = np.round(
                np.clip(foreground[mixed], 0.0, 255.0)
            ).astype(np.uint8)
        rgba[..., 3] = np.round(alpha * 255).astype(np.uint8)
        visible = rgba[..., 3] > 0
        blue_spill = visible & (
            rgba[..., 2].astype(np.int16)
            > np.maximum(rgba[..., 0], rgba[..., 1]).astype(np.int16)
        )
        rgba[..., 2][blue_spill] = np.maximum(
            rgba[..., 0], rgba[..., 1]
        )[blue_spill]
        cyan_spill = (
            visible
            & (rgba[..., 1].astype(np.int16) > rgba[..., 0].astype(np.int16) + 8)
            & (rgba[..., 2].astype(np.int16) > rgba[..., 0].astype(np.int16) + 8)
        )
        rgba[..., 1][cyan_spill] = rgba[..., 0][cyan_spill]
        rgba[..., 2][cyan_spill] = rgba[..., 0][cyan_spill]
        rgba[rgba[..., 3] == 0, :3] = 0
        return rgba

    minimum = rgb.min(axis=2)
    maximum = rgb.max(axis=2)
    spread = maximum - minimum

    # Generated checkerboards use near-white neutral squares. Character fur,
    # clothes, skin, and rim light are either darker or chromatic.
    background = (minimum >= 226) & (spread <= 18)
    rgba[..., 3] = np.where(background, 0, 255).astype(np.uint8)
    rgba[background, :3] = 0
    return rgba


def _components(
    alpha: np.ndarray,
) -> tuple[list[tuple[int, int, int, int, int, int]], np.ndarray]:
    # Ignore near-transparent antialiasing dust. It can otherwise bridge two
    # neighbouring figures into one false component.
    mask = alpha > 16
    height, width = mask.shape
    visited = np.zeros_like(mask, dtype=bool)
    labels = np.zeros(mask.shape, dtype=np.int16)
    found: list[tuple[int, int, int, int, int, int]] = []
    label = 0
    for y in range(height):
        for x in range(width):
            if not mask[y, x] or visited[y, x]:
                continue
            label += 1
            queue: deque[tuple[int, int]] = deque([(x, y)])
            visited[y, x] = True
            labels[y, x] = label
            min_x = max_x = x
            min_y = max_y = y
            size = 0
            while queue:
                px, py = queue.popleft()
                size += 1
                min_x = min(min_x, px)
                max_x = max(max_x, px)
                min_y = min(min_y, py)
                max_y = max(max_y, py)
                for nx, ny in (
                    (px - 1, py),
                    (px + 1, py),
                    (px, py - 1),
                    (px, py + 1),
                ):
                    if (
                        0 <= nx < width
                        and 0 <= ny < height
                        and mask[ny, nx]
                        and not visited[ny, nx]
                    ):
                        visited[ny, nx] = True
                        labels[ny, nx] = label
                        queue.append((nx, ny))
            found.append((size, label, min_x, min_y, max_x + 1, max_y + 1))
    return sorted(found, reverse=True), labels


def _component_subject(
    rgba: np.ndarray,
    labels: np.ndarray,
    component: tuple[int, int, int, int, int, int],
) -> Image.Image:
    _, label, left, top, right, bottom = component
    padding = 4
    left = max(0, left - padding)
    top = max(0, top - padding)
    right = min(rgba.shape[1], right + padding)
    bottom = min(rgba.shape[0], bottom + padding)
    selected = labels[top:bottom, left:right] == label

    # Restore the selected figure's soft antialiased edge without admitting
    # distant body parts from a neighbouring sprite-sheet panel.
    keep = selected.copy()
    for _ in range(3):
        padded = np.pad(keep, 1)
        keep = np.logical_or.reduce(
            [
                padded[y : y + keep.shape[0], x : x + keep.shape[1]]
                for y in range(3)
                for x in range(3)
            ]
        )

    subject = rgba[top:bottom, left:right].copy()
    subject[~keep] = 0
    return Image.fromarray(subject)


def _normalize(subjects: list[Image.Image]) -> list[Image.Image]:
    available_width = CANVAS[0] - SIDE_MARGIN * 2
    available_height = CANVAS[1] - TOP_MARGIN - BOTTOM_MARGIN
    scale = min(
        min(available_width / subject.width, available_height / subject.height)
        for subject in subjects
    )
    outputs: list[Image.Image] = []
    for subject in subjects:
        target = (
            max(1, round(subject.width * scale)),
            max(1, round(subject.height * scale)),
        )
        resized = subject.resize(target, Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
        x = (CANVAS[0] - resized.width) // 2
        y = CANVAS[1] - BOTTOM_MARGIN - resized.height
        canvas.alpha_composite(resized, (x, y))
        outputs.append(canvas)
    return outputs


def _write_single(rgba: np.ndarray, output: Path) -> None:
    components, labels = _components(rgba[..., 3])
    components = [item for item in components if item[0] > 2000]
    if not components:
        raise ValueError("No connected character found")
    subject = _component_subject(rgba, labels, components[0])
    output.parent.mkdir(parents=True, exist_ok=True)
    _normalize([subject])[0].save(output, optimize=True, compress_level=9)


def _write_sheet(rgba: np.ndarray, output_dir: Path) -> None:
    subjects: list[Image.Image] = []
    height, width = rgba.shape[:2]
    for index in range(4):
        panel_width = width / 4
        x0 = round(index * panel_width)
        x1 = round((index + 1) * panel_width)
        panel = rgba[:, x0:x1].copy()
        components, labels = _components(panel[..., 3])
        if not components or components[0][0] <= 2000:
            raise ValueError(f"No connected character in panel {index + 1}")
        subjects.append(_component_subject(panel, labels, components[0]))
    output_dir.mkdir(parents=True, exist_ok=True)
    names = ("double_biceps", "chest_flex", "leg_pose", "triceps")
    frames = _normalize(subjects)
    if len(frames) != len(names):
        raise ValueError("Expected exactly four generated poses")
    for name, frame in zip(names, frames):
        frame.save(output_dir / f"{name}.png", optimize=True, compress_level=9)


def main() -> None:
    args = _arguments()
    rgba = _rgba_without_checker(args.input)
    if args.output:
        _write_single(rgba, args.output)
    else:
        _write_sheet(rgba, args.sheet_output_dir)


if __name__ == "__main__":
    main()
