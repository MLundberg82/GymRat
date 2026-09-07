#!/usr/bin/env python3
"""Author the level-1 front double-biceps armature action for one identity.

This script intentionally edits only the external Blender source scene. It
does not render or register runtime sprites until a character mesh has been
bound and the resulting motion has passed owner review.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector


ACTION_NAME = "ACT_front_double_biceps"
POSE_BONES = (
    "upper_arm.L",
    "forearm.L",
    "hand.L",
    "upper_arm.R",
    "forearm.R",
    "hand.R",
    "thigh.L",
    "shin.L",
    "foot.L",
)


def _arguments() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, required=True)
    parser.add_argument("--source-root", type=Path, required=True)
    parser.add_argument(
        "--identity",
        choices=("male", "female", "non_binary"),
        default="male",
    )
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args(argv)


def _new_action(rig: bpy.types.Object) -> bpy.types.Action:
    previous = bpy.data.actions.get(ACTION_NAME)
    properties: dict[str, object] = {}
    markers: list[tuple[str, int]] = []
    if previous is not None:
        properties = {key: previous[key] for key in previous.keys()}
        markers = [(marker.name, marker.frame) for marker in previous.pose_markers]
        if rig.animation_data is not None and rig.animation_data.action == previous:
            rig.animation_data.action = None
        bpy.data.actions.remove(previous)

    action = bpy.data.actions.new(name=ACTION_NAME)
    action.use_fake_user = True
    for key, value in properties.items():
        action[key] = value
    for name, frame in markers:
        marker = action.pose_markers.new(name)
        marker.frame = frame
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
    rotation = (
        Vector(direction)
        .normalized()
        .to_track_quat("Y", "Z")
        .to_matrix()
        .to_4x4()
    )
    bone.matrix = Matrix.Translation(bone.head.copy()) @ rotation
    bpy.context.view_layer.update()


def _straight_arms(rig: bpy.types.Object) -> None:
    for side, sign in (("L", 1.0), ("R", -1.0)):
        direction = (sign, 0.0, 0.0)
        _aim(rig, f"upper_arm.{side}", direction)
        _aim(rig, f"forearm.{side}", direction)
        _aim(rig, f"hand.{side}", direction)


def _contracted_arms(rig: bpy.types.Object) -> None:
    _aim(rig, "upper_arm.L", (1.0, 0.0, 0.0))
    _aim(rig, "forearm.L", (-0.42, 0.0, 0.91))
    _aim(rig, "hand.L", (-0.65, 0.0, 0.15))
    _aim(rig, "upper_arm.R", (-1.0, 0.0, 0.0))
    _aim(rig, "forearm.R", (0.42, 0.0, 0.91))
    _aim(rig, "hand.R", (0.65, 0.0, 0.15))


def _step_leg(rig: bpy.types.Object, amount: float) -> None:
    # The hip/root never translates. Only the left leg advances toward the
    # front camera and outward while the toe remains on the shared foot line.
    _aim(rig, "thigh.L", (0.18 * amount, -0.22 * amount, -1.0))
    _aim(rig, "shin.L", (-0.03 * amount, -0.23 * amount, -1.0))
    _aim(rig, "foot.L", (0.28 * amount, -0.82, -0.46))


def _keyframe(rig: bpy.types.Object, frame: int) -> None:
    for name in POSE_BONES:
        bone = rig.pose.bones[name]
        bone.keyframe_insert("location", frame=frame, group=name)
        bone.keyframe_insert("rotation_quaternion", frame=frame, group=name)
        bone.keyframe_insert("scale", frame=frame, group=name)


def _author(rig: bpy.types.Object) -> bpy.types.Action:
    action = _new_action(rig)
    rig.animation_data_create()
    rig.animation_data.action = action

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
        if pose == "entry":
            _straight_arms(rig)
            _step_leg(rig, 0.45)
        elif pose == "hold":
            _contracted_arms(rig)
            _step_leg(rig, 1.0)
        _keyframe(rig, frame)

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

    action["gymrat_frames"] = 48
    action["gymrat_loop"] = False
    action["gymrat_view"] = "front"
    action["gymrat_authored_pilot"] = True
    action["gymrat_pose_spec"] = json.dumps(
        {
            "entry": "both arms extend straight outward to shoulder height",
            "hold_front": "elbows bend inward, upper arms remain at shoulder height, one leg steps forward and outward",
            "hold_back": "elbows bend as in front pose, one foot steps back and rests on the toes",
        }
    )
    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = 48
    bpy.context.scene.frame_set(1)
    return action


def main() -> None:
    args = _arguments()
    scene_path = args.source_root / "scenes" / f"{args.identity}_character.blend"
    if not scene_path.is_file():
        raise FileNotFoundError(scene_path)
    bpy.ops.wm.open_mainfile(filepath=str(scene_path))
    rig = bpy.data.objects.get("RIG_GYMRAT")
    if rig is None or rig.type != "ARMATURE":
        raise RuntimeError("RIG_GYMRAT armature is missing")

    action = _author(rig)
    start, end = action.curve_frame_range
    if len(action.layers) == 0 or start > 1 or end < 48:
        raise RuntimeError("Double-biceps pilot did not create a complete action")

    if args.dry_run:
        print(f"Validated {ACTION_NAME} frames {start:g}-{end:g} without saving")
        return
    bpy.ops.wm.save_as_mainfile(filepath=str(scene_path))
    print(f"Authored {ACTION_NAME} frames {start:g}-{end:g} in {scene_path}")


if __name__ == "__main__":
    main()
