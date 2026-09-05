#!/usr/bin/env python3
"""Validate GymRat Blender scenes against the checked-in rig contract."""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import bpy


def _arguments() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, required=True)
    parser.add_argument("--source-root", type=Path, required=True)
    parser.add_argument("--require-render-ready", action="store_true")
    return parser.parse_args(argv)


def _close(actual: float, expected: float) -> bool:
    return math.isclose(actual, expected, abs_tol=0.0001)


def _validate_scene(
    scene_path: Path,
    identity: str,
    manifest: dict[str, object],
    require_render_ready: bool,
) -> list[str]:
    if not scene_path.is_file():
        return [f"missing scene: {scene_path}"]

    bpy.ops.wm.open_mainfile(filepath=str(scene_path))
    scene = bpy.context.scene
    errors: list[str] = []
    if scene.get("gymrat_identity") != identity:
        errors.append(f"{identity}: embedded identity is incorrect")
    if scene.get("gymrat_pipeline_version") != manifest["version"]:
        errors.append(f"{identity}: embedded pipeline version is stale")
    embedded_emotes = scene.get("gymrat_emote_contract")
    if embedded_emotes is None or json.loads(embedded_emotes) != manifest[
        "emote_contract"
    ]:
        errors.append(f"{identity}: embedded emote contract is stale")

    emote_contract = manifest["emote_contract"]
    emote_types = set(emote_contract["types"])
    for motion, definition in manifest["motions"].items():
        views = emote_contract["views"] if motion in emote_types else (None,)
        for view in views:
            action_name = motion if view is None else f"{view}_{motion}"
            action = bpy.data.actions.get(f"ACT_{action_name}")
            if action is None:
                errors.append(f"{identity}: ACT_{action_name} action is missing")
                continue
            if action.get("gymrat_frames") != definition["frames"]:
                errors.append(
                    f"{identity}: ACT_{action_name} frame contract is stale"
                )
            if action.get("gymrat_loop") != definition["loop"]:
                errors.append(
                    f"{identity}: ACT_{action_name} loop contract is stale"
                )
            if view is not None:
                if action.get("gymrat_view") != view:
                    errors.append(f"{identity}: ACT_{action_name} view is stale")
                pose_spec = action.get("gymrat_pose_spec")
                if pose_spec is None or json.loads(pose_spec) != emote_contract[
                    "pose_specs"
                ][motion]:
                    errors.append(
                        f"{identity}: ACT_{action_name} pose spec is stale"
                    )
                markers = {
                    marker.name: marker.frame for marker in action.pose_markers
                }
                expected_markers = {
                    "NEUTRAL_START": 1,
                    "ENTRY_READABLE": 10,
                    "FULL_CONTRACTION": 24,
                    "HOLD_END": 38,
                    "NEUTRAL_END": 48,
                }
                if markers != expected_markers:
                    errors.append(
                        f"{identity}: ACT_{action_name} markers are stale"
                    )
                if require_render_ready:
                    curve_start, curve_end = action.curve_frame_range
                    if (
                        len(action.layers) == 0
                        or curve_start > 1
                        or curve_end < definition["frames"]
                    ):
                        errors.append(
                            f"{identity}: ACT_{action_name} has no complete "
                            "authored bone animation"
                        )

    rig = bpy.data.objects.get("RIG_GYMRAT")
    if rig is None or rig.type != "ARMATURE":
        return errors + [f"{identity}: RIG_GYMRAT armature is missing"]

    tail = manifest["anatomy_contract"]["tail_anchor"]
    root = rig.data.bones.get(tail["bone"])
    if root is None:
        return errors + [f"{identity}: {tail['bone']} bone is missing"]
    if root.parent is None or root.parent.name != tail["parent"]:
        errors.append(f"{identity}: tail root is not parented to pelvis")

    for label, actual, expected in (
        ("head", root.head_local, tail["head"]),
        ("tail", root.tail_local, tail["tail"]),
    ):
        if any(
            not _close(float(actual[index]), float(expected[index]))
            for index in range(3)
        ):
            errors.append(f"{identity}: tail root {label} violates manifest")

    embedded = rig.get("gymrat_tail_anchor_contract")
    if embedded is None or json.loads(embedded) != tail:
        errors.append(f"{identity}: embedded tail contract is stale")

    if require_render_ready:
        model = bpy.data.collections.get("MODEL_AUTHORED")
        meshes = (
            []
            if model is None
            else [obj for obj in model.objects if obj.type == "MESH"]
        )
        if not meshes:
            errors.append(f"{identity}: authored character mesh is missing")
        for mesh in meshes:
            modifiers = [
                modifier
                for modifier in mesh.modifiers
                if modifier.type == "ARMATURE" and modifier.object == rig
            ]
            if not modifiers:
                errors.append(
                    f"{identity}: {mesh.name} is not bound to RIG_GYMRAT"
                )
    return errors


def main() -> int:
    args = _arguments()
    manifest_path = args.repo_root / "tool/character_pipeline/pipeline_manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    errors: list[str] = []
    for identity in manifest["identities"]:
        errors.extend(
            _validate_scene(
                args.source_root / "scenes" / f"{identity}_character.blend",
                identity,
                manifest,
                args.require_render_ready,
            )
        )

    if errors:
        print("Blender scene validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    scope = (
        "render-ready Blender scenes"
        if args.require_render_ready
        else "Blender contracts"
    )
    print(f"Validated {scope} for {len(manifest['identities'])} identities.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
