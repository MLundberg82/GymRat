#!/usr/bin/env python3
"""Author the complete GymRat motion library on one Blender identity rig."""

from __future__ import annotations

import argparse
import json
import math
import sys
import traceback
from pathlib import Path

import bpy
from mathutils import Euler, Matrix, Vector


IDENTITIES = ("male", "female", "non_binary")
EMOTES = ("double_biceps", "chest_flex", "leg_pose", "triceps")
POSE_BONES = (
    "pelvis",
    "spine_01",
    "spine_02",
    "chest",
    "neck",
    "head",
    "eyelid.L",
    "eyelid.R",
    "upper_arm.L",
    "forearm.L",
    "hand.L",
    "upper_arm.R",
    "forearm.R",
    "hand.R",
    "thigh.L",
    "shin.L",
    "foot.L",
    "thigh.R",
    "shin.R",
    "foot.R",
    *(f"tail_{index:02d}" for index in range(1, 11)),
)


def _arguments() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, required=True)
    parser.add_argument("--source-root", type=Path, required=True)
    parser.add_argument("--identity", choices=IDENTITIES, required=True)
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args(argv)


def _new_action(rig: bpy.types.Object, name: str) -> bpy.types.Action:
    previous = bpy.data.actions.get(name)
    if previous is not None:
        if rig.animation_data is not None and rig.animation_data.action == previous:
            rig.animation_data.action = None
        bpy.data.actions.remove(previous)
    action = bpy.data.actions.new(name=name)
    action.use_fake_user = True
    rig.animation_data_create()
    rig.animation_data.action = action
    return action


def _reset(rig: bpy.types.Object) -> None:
    for name in POSE_BONES:
        bone = rig.pose.bones[name]
        bone.rotation_mode = "QUATERNION"
        bone.matrix_basis.identity()
    bpy.context.view_layer.update()


def _aim(rig: bpy.types.Object, name: str, direction: tuple[float, float, float]) -> None:
    bone = rig.pose.bones[name]
    bpy.context.view_layer.update()
    rotation = Vector(direction).normalized().to_track_quat("Y", "Z").to_matrix().to_4x4()
    bone.matrix = Matrix.Translation(bone.head.copy()) @ rotation
    bpy.context.view_layer.update()


def _rotate_local(
    rig: bpy.types.Object, name: str, angles: tuple[float, float, float]
) -> None:
    bone = rig.pose.bones[name]
    bone.rotation_mode = "QUATERNION"
    bone.rotation_quaternion = Euler(angles, "XYZ").to_quaternion()


def _keyframe(rig: bpy.types.Object, frame: int, names=POSE_BONES) -> None:
    for name in names:
        bone = rig.pose.bones[name]
        bone.keyframe_insert("location", frame=frame, group=name)
        bone.keyframe_insert("rotation_quaternion", frame=frame, group=name)
        bone.keyframe_insert("scale", frame=frame, group=name)


def _straight_arms(rig: bpy.types.Object) -> None:
    for side, sign in (("L", 1.0), ("R", -1.0)):
        direction = (sign, 0.0, 0.0)
        _aim(rig, f"upper_arm.{side}", direction)
        _aim(rig, f"forearm.{side}", direction)
        _aim(rig, f"hand.{side}", direction)


def _double_biceps(rig: bpy.types.Object, view: str) -> None:
    depth = 0.06 if view == "front" else -0.06
    _aim(rig, "upper_arm.L", (1.0, depth, 0.0))
    _aim(rig, "forearm.L", (-0.42, depth, 0.91))
    _aim(rig, "hand.L", (-0.65, depth, 0.15))
    _aim(rig, "upper_arm.R", (-1.0, depth, 0.0))
    _aim(rig, "forearm.R", (0.42, depth, 0.91))
    _aim(rig, "hand.R", (0.65, depth, 0.15))


def _side_chest(rig: bpy.types.Object, view: str) -> None:
    depth = -0.50 if view == "front" else 0.50
    _aim(rig, "upper_arm.L", (0.72, depth, -0.18))
    _aim(rig, "forearm.L", (-0.72, depth * 0.35, 0.52))
    _aim(rig, "hand.L", (-0.28, depth * 0.3, 0.05))
    _aim(rig, "upper_arm.R", (-0.38, -depth, -0.22))
    _aim(rig, "forearm.R", (0.60, depth * 0.25, 0.25))
    _aim(rig, "hand.R", (0.35, depth * 0.2, 0.05))
    _side_chest_legs(rig, view, 1.0)
    _rotate_local(rig, "chest", (0.02, 0.0, -0.13))


def _side_chest_entry(rig: bpy.types.Object, view: str) -> None:
    depth = -0.28 if view == "front" else 0.28
    _aim(rig, "upper_arm.L", (0.82, depth, -0.10))
    _aim(rig, "forearm.L", (-0.78, depth * 0.24, 0.34))
    _aim(rig, "hand.L", (-0.24, depth * 0.18, 0.04))
    _aim(rig, "upper_arm.R", (-0.58, -depth, -0.13))
    _aim(rig, "forearm.R", (0.72, depth * 0.16, 0.16))
    _aim(rig, "hand.R", (0.31, depth * 0.12, 0.04))
    _side_chest_legs(rig, view, 0.45)
    _rotate_local(rig, "chest", (0.01, 0.0, -0.06))


def _side_chest_legs(rig: bpy.types.Object, view: str, amount: float) -> None:
    """Bend the presented leg and keep its foot pointed onto the toes."""
    depth = -0.18 if view == "front" else 0.18
    _aim(rig, "thigh.L", (0.12 * amount, depth * amount, -1.0))
    _aim(rig, "shin.L", (-0.04 * amount, depth * amount, -1.0))
    _aim(rig, "foot.L", (0.12 * amount, -0.35, -0.94))


def _leg_pose(rig: bpy.types.Object, view: str) -> None:
    depth = 0.20 if view == "front" else -0.20
    _aim(rig, "upper_arm.L", (0.68, depth, 0.73))
    _aim(rig, "forearm.L", (-0.62, depth, 0.72))
    _aim(rig, "hand.L", (-0.24, 0.35, 0.18))
    _aim(rig, "upper_arm.R", (-0.68, depth, 0.73))
    _aim(rig, "forearm.R", (0.62, depth, 0.72))
    _aim(rig, "hand.R", (0.24, 0.35, 0.18))
    _aim(rig, "thigh.L", (0.20, -0.28, -1.0))
    _aim(rig, "shin.L", (-0.04, -0.22, -1.0))
    _aim(rig, "foot.L", (0.31, -0.83, -0.45))
    _rotate_local(rig, "spine_02", (0.06, 0.0, 0.0))


def _leg_pose_entry(rig: bpy.types.Object, view: str) -> None:
    depth = 0.12 if view == "front" else -0.12
    _aim(rig, "upper_arm.L", (0.82, depth, 0.48))
    _aim(rig, "forearm.L", (-0.72, depth, 0.54))
    _aim(rig, "hand.L", (-0.18, 0.20, 0.14))
    _aim(rig, "upper_arm.R", (-0.82, depth, 0.48))
    _aim(rig, "forearm.R", (0.72, depth, 0.54))
    _aim(rig, "hand.R", (0.18, 0.20, 0.14))
    _step_leg(rig, view, 0.45)
    _rotate_local(rig, "spine_02", (0.025, 0.0, 0.0))


def _side_triceps(rig: bpy.types.Object, view: str) -> None:
    rear = 0.62 if view == "front" else -0.62
    _aim(rig, "upper_arm.L", (0.32, rear, -0.72))
    _aim(rig, "forearm.L", (-0.18, rear, -0.92))
    _aim(rig, "hand.L", (-0.55, rear, 0.08))
    _aim(rig, "upper_arm.R", (-0.24, rear, -0.74))
    _aim(rig, "forearm.R", (0.28, rear, -0.88))
    _aim(rig, "hand.R", (0.55, rear, 0.08))
    _side_triceps_legs(rig, view, 1.0)
    _rotate_local(rig, "chest", (-0.02, 0.0, 0.10))


def _side_triceps_entry(rig: bpy.types.Object, view: str) -> None:
    rear = 0.34 if view == "front" else -0.34
    _aim(rig, "upper_arm.L", (0.52, rear, -0.46))
    _aim(rig, "forearm.L", (-0.12, rear, -0.78))
    _aim(rig, "hand.L", (-0.36, rear, 0.06))
    _aim(rig, "upper_arm.R", (-0.47, rear, -0.48))
    _aim(rig, "forearm.R", (0.16, rear, -0.76))
    _aim(rig, "hand.R", (0.36, rear, 0.06))
    _side_triceps_legs(rig, view, 0.45)
    _rotate_local(rig, "chest", (-0.01, 0.0, 0.045))


def _side_triceps_legs(rig: bpy.types.Object, view: str, amount: float) -> None:
    """Keep the near foot planted while the far foot rises onto its toes."""
    depth = 0.17 if view == "front" else -0.17
    _aim(rig, "thigh.R", (-0.09 * amount, depth * amount, -1.0))
    _aim(rig, "shin.R", (0.03 * amount, depth * amount, -1.0))
    _aim(rig, "foot.R", (-0.10 * amount, -0.33, -0.94))


def _step_leg(rig: bpy.types.Object, view: str, amount: float = 1.0) -> None:
    depth = -0.22 if view == "front" else 0.22
    _aim(rig, "thigh.L", (0.18 * amount, depth * amount, -1.0))
    _aim(rig, "shin.L", (-0.03 * amount, depth * amount, -1.0))
    _aim(rig, "foot.L", (0.28 * amount, -0.82, -0.46))


def _set_emote_pose(rig: bpy.types.Object, motion: str, view: str, pose: str) -> None:
    if pose == "neutral":
        return
    if pose == "entry":
        if motion == "double_biceps":
            _straight_arms(rig)
        elif motion == "chest_flex":
            _side_chest_entry(rig, view)
        elif motion == "leg_pose":
            _leg_pose_entry(rig, view)
        elif motion == "triceps":
            _side_triceps_entry(rig, view)
        return
    if motion == "double_biceps":
        _double_biceps(rig, view)
    elif motion == "chest_flex":
        _side_chest(rig, view)
    elif motion == "leg_pose":
        _leg_pose(rig, view)
    elif motion == "triceps":
        _side_triceps(rig, view)


def _finish_curves(action: bpy.types.Action) -> None:
    for layer in action.layers:
        for strip in layer.strips:
            for slot in action.slots:
                channelbag = strip.channelbag(slot, ensure=False)
                if channelbag is None:
                    continue
                for curve in channelbag.fcurves:
                    for point in curve.keyframe_points:
                        point.interpolation = "BEZIER"
                        point.handle_left_type = "AUTO_CLAMPED"
                        point.handle_right_type = "AUTO_CLAMPED"


def _author_emote(
    rig: bpy.types.Object,
    motion: str,
    view: str,
    definition: dict[str, object],
    pose_spec: dict[str, str],
) -> None:
    action = _new_action(rig, f"ACT_{view}_{motion}")
    for frame, pose in (
        (1, "neutral"),
        (10, "entry"),
        (24, "hold"),
        (38, "hold"),
        (43, "entry"),
        (48, "neutral"),
    ):
        bpy.context.scene.frame_set(frame)
        _reset(rig)
        _set_emote_pose(rig, motion, view, pose)
        _keyframe(rig, frame)
    action["gymrat_frames"] = int(definition["frames"])
    action["gymrat_loop"] = bool(definition["loop"])
    action["gymrat_view"] = view
    action["gymrat_pose_spec"] = json.dumps(pose_spec)
    for marker_name, frame in (
        ("NEUTRAL_START", 1),
        ("ENTRY_READABLE", 10),
        ("FULL_CONTRACTION", 24),
        ("HOLD_END", 38),
        ("NEUTRAL_END", 48),
    ):
        action.pose_markers.new(marker_name).frame = frame
    _finish_curves(action)


def _author_simple(
    rig: bpy.types.Object, motion: str, definition: dict[str, object]
) -> None:
    action = _new_action(rig, f"ACT_{motion}")
    frames = int(definition["frames"])
    checkpoints = sorted({1, frames // 4, frames // 2, frames * 3 // 4, frames})
    for frame in checkpoints:
        bpy.context.scene.frame_set(frame)
        _reset(rig)
        phase = (frame - 1) / max(1, frames - 1)
        wave = math.sin(phase * math.tau)
        if motion == "idle_breath":
            rig.pose.bones["chest"].scale = (1.0 + 0.008 * wave, 1.0 + 0.006 * wave, 1.0 + 0.014 * wave)
        elif motion == "blink":
            closure = 1.0 if frame in {frames // 2} else max(0.0, math.sin(phase * math.pi))
            for side in ("L", "R"):
                rig.pose.bones[f"eyelid.{side}"].scale = (1.0, 1.0, 1.0 - 0.82 * closure)
        elif motion == "tail_idle":
            for index in range(1, 11):
                _rotate_local(rig, f"tail_{index:02d}", (0.0, 0.0, wave * (0.035 + index * 0.006)))
        elif motion == "victory":
            lift = math.sin(phase * math.pi)
            _aim(rig, "upper_arm.L", (0.45, 0.0, 0.65 + lift))
            _aim(rig, "forearm.L", (0.25, 0.0, 0.85))
            _aim(rig, "upper_arm.R", (-0.45, 0.0, 0.65 + lift))
            _aim(rig, "forearm.R", (-0.25, 0.0, 0.85))
        elif motion == "pb_celebration":
            lift = math.sin(phase * math.pi)
            _aim(rig, "upper_arm.L", (0.55, 0.0, 0.35 + lift))
            _aim(rig, "forearm.L", (0.15, 0.0, 0.95))
            _rotate_local(rig, "chest", (0.0, 0.0, -0.08 * lift))
        elif motion == "recovery":
            _rotate_local(rig, "spine_02", (0.018 * wave, 0.0, 0.012 * wave))
            _rotate_local(rig, "head", (-0.012 * wave, 0.0, 0.0))
        _keyframe(rig, frame)
    action["gymrat_frames"] = frames
    action["gymrat_loop"] = bool(definition["loop"])
    _finish_curves(action)


def main() -> None:
    args = _arguments()
    manifest = json.loads(
        (args.repo_root / "tool/character_pipeline/pipeline_manifest.json").read_text(
            encoding="utf-8"
        )
    )
    scene_path = args.source_root / "scenes" / f"{args.identity}_character.blend"
    if not scene_path.is_file():
        raise FileNotFoundError(scene_path)
    bpy.ops.wm.open_mainfile(filepath=str(scene_path))
    rig = bpy.data.objects.get("RIG_GYMRAT")
    if rig is None or rig.type != "ARMATURE":
        raise RuntimeError("RIG_GYMRAT armature is missing")
    for motion, definition in manifest["motions"].items():
        if motion in EMOTES:
            for view in manifest["emote_contract"]["views"]:
                _author_emote(
                    rig,
                    motion,
                    view,
                    definition,
                    manifest["emote_contract"]["pose_specs"][motion],
                )
        else:
            _author_simple(rig, motion, definition)
    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = max(
        int(definition["frames"]) for definition in manifest["motions"].values()
    )
    bpy.context.scene.frame_set(1)
    if args.dry_run:
        print(f"Authored complete motion library for {args.identity} without saving")
        return
    bpy.ops.wm.save_as_mainfile(filepath=str(scene_path))
    print(f"Authored complete motion library for {args.identity} in {scene_path}")


if __name__ == "__main__":
    try:
        main()
    except Exception:
        traceback.print_exc()
        raise SystemExit(1)
