#!/usr/bin/env python3
"""Build a review-only anatomical GymRat body with the CC0 MPFB basemesh.

MPFB supplies one consistent, detailed human body topology and production
skinning. The approved GymRat front/back masters remain the identity source for
the rat head, outfit direction, palette and tail. Runtime assets are never
written by this pilot and every saved scene remains explicitly review-gated.
"""

from __future__ import annotations

import argparse
import importlib
import json
import math
import sys
import traceback
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))

from build_topology_donor_pilot import (
    STAGE_PROGRESS,
    _add_fist_coverage,
    _add_tail_bones,
    _add_tail_mesh,
    _bell,
    _build_master_shell,
    _clear_collection,
    _move_to_collection,
    _physical_material,
    _preview,
    _smoothstep,
)


IDENTITIES = ("male", "female", "non_binary")
BODY_SCALE = 2.04
BODY_OFFSET_Z = 0.10

MPFB_BONE_MAP = {
    "Root": "root",
    "pelvis": "pelvis",
    "spine_01": "spine_01",
    "spine_02": "spine_02",
    "spine_03": "chest",
    "neck_01": "neck",
    "head": "head",
    "clavicle_l": "clavicle.L",
    "clavicle_r": "clavicle.R",
    "upperarm_l": "upper_arm.L",
    "upperarm_r": "upper_arm.R",
    "lowerarm_l": "forearm.L",
    "lowerarm_r": "forearm.R",
    "hand_l": "hand.L",
    "hand_r": "hand.R",
    "thigh_l": "thigh.L",
    "thigh_r": "thigh.R",
    "calf_l": "shin.L",
    "calf_r": "shin.R",
    "foot_l": "foot.L",
    "foot_r": "foot.R",
}


def _arguments() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, required=True)
    parser.add_argument("--source-root", type=Path, required=True)
    parser.add_argument("--identity", choices=IDENTITIES, required=True)
    parser.add_argument("--stage", type=int, default=1)
    parser.add_argument("--view", choices=("front", "back"), default="front")
    parser.add_argument("--motion")
    parser.add_argument("--frame", type=int, default=1)
    parser.add_argument("--render-preview", type=Path)
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args(argv)


def _mpfb_service(module_suffix: str, name: str):
    module_name = next(
        (loaded for loaded in sys.modules if loaded.endswith(module_suffix)),
        None,
    )
    if module_name is None:
        raise RuntimeError(
            "MPFB is not enabled in Blender. Install the official extension first."
        )
    return getattr(importlib.import_module(module_name), name)


def _macro(identity: str, progress: float, target_service) -> dict[str, object]:
    values = target_service.get_default_macro_info_dict()
    values.update(
        {
            "gender": {"male": 1.0, "female": 0.0, "non_binary": 0.50}[
                identity
            ],
            "age": 0.50,
            # Muscularity grows while body fat stays lean and stable. MPFB's
            # `weight` macro changes the soft-tissue silhouette, so varying it
            # by level creates the padded/fat-suit look that the production
            # contract explicitly rejects. Stage mass comes from the muscle
            # target and the regional Olympia overdrive below instead.
            "muscle": {
                "male": 0.36,
                "female": 0.28,
                "non_binary": 0.31,
            }[identity]
            + progress
            * {
                "male": 0.64,
                "female": 0.72,
                "non_binary": 0.69,
            }[identity],
            "weight": 0.40,
            "height": 0.62,
            "proportions": 0.66,
            "cupsize": 0.34 if identity == "female" else 0.0,
            "firmness": 0.72,
        }
    )
    return values


def _evaluated_coordinates(obj: bpy.types.Object) -> list[Vector]:
    depsgraph = bpy.context.evaluated_depsgraph_get()
    evaluated = obj.evaluated_get(depsgraph)
    return [vertex.co.copy() for vertex in evaluated.data.vertices]


def _remove_object(obj: bpy.types.Object) -> None:
    bpy.data.objects.remove(obj, do_unlink=True)


def _build_stage_coordinates(
    identity: str,
    stages: list[int],
    human_service,
    target_service,
) -> tuple[bpy.types.Object, dict[int, list[Vector]]]:
    stage_coordinates: dict[int, list[Vector]] = {}
    base: bpy.types.Object | None = None
    for level in stages:
        progress = STAGE_PROGRESS.get(
            level, stages.index(level) / max(1, len(stages) - 1)
        )
        human = human_service.create_human(
            mask_helpers=True,
            detailed_helpers=True,
            extra_vertex_groups=True,
            feet_on_ground=True,
            # MPFB's game-engine rig normalizes the imported decimeter body by
            # one half while it fits joints. Start at 0.2 so the resulting
            # rigged coordinates remain at the intended meter baseline before
            # the GymRat canvas conversion below.
            scale=0.2,
            macro_detail_dict=_macro(identity, progress, target_service),
        )
        helper_masks = [
            modifier for modifier in human.modifiers if modifier.type == "MASK"
        ]
        for modifier in helper_masks:
            modifier.show_viewport = False
            modifier.show_render = False
        coordinates = _evaluated_coordinates(human)
        if level == stages[0]:
            for modifier in helper_masks:
                modifier.show_viewport = True
                modifier.show_render = True
        if stage_coordinates and len(coordinates) != len(next(iter(stage_coordinates.values()))):
            raise RuntimeError("MPFB topology changed between physique milestones")
        stage_coordinates[level] = coordinates
        if level == stages[0]:
            base = human
        else:
            _remove_object(human)
    if base is None:
        raise RuntimeError("MPFB did not create a level-1 body")
    return base, stage_coordinates


def _rename_rig(rig: bpy.types.Object, body: bpy.types.Object) -> None:
    for old_name, new_name in MPFB_BONE_MAP.items():
        bone = rig.data.bones.get(old_name)
        if bone is not None:
            bone.name = new_name
        group = body.vertex_groups.get(old_name)
        if group is not None:
            group.name = new_name
    rig.name = "RIG_GYMRAT"
    rig.data.name = "RIG_GYMRAT_DATA"


def _lower_rest_arms(body: bpy.types.Object, rig: bpy.types.Object) -> None:
    """Bake MPFB's A-pose into GymRat's relaxed, planted neutral stance."""
    bpy.context.view_layer.objects.active = rig
    rig.select_set(True)
    bpy.ops.object.mode_set(mode="POSE")

    def aim(name: str, direction: Vector) -> None:
        bone = rig.pose.bones[name]
        bpy.context.view_layer.update()
        rotation = direction.normalized().to_track_quat("Y", "Z").to_matrix().to_4x4()
        bone.matrix = Matrix.Translation(bone.head.copy()) @ rotation
        bpy.context.view_layer.update()

    for side in ("L", "R"):
        upper = rig.pose.bones[f"upper_arm.{side}"]
        sign = 1.0 if upper.head.x >= 0 else -1.0
        aim(f"upper_arm.{side}", Vector((0.16 * sign, 0.0, -1.0)))
        aim(f"forearm.{side}", Vector((0.08 * sign, 0.0, -1.0)))
        aim(f"hand.{side}", Vector((0.03 * sign, 0.0, -1.0)))
    # This operator preserves the visibly deformed mesh while recalculating the
    # armature's rest/bind matrices. Manual edit-bone movement cannot do that.
    bpy.ops.pose.armature_apply(selected=False)
    bpy.ops.object.mode_set(mode="OBJECT")


def _add_face_motion_bones(rig: bpy.types.Object) -> None:
    bpy.context.view_layer.objects.active = rig
    rig.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    head = rig.data.edit_bones.get("head")
    if head is None:
        raise RuntimeError("Converted MPFB rig has no head bone")
    for name, x in (("eyelid.L", 0.13), ("eyelid.R", -0.13)):
        old = rig.data.edit_bones.get(name)
        if old is not None:
            rig.data.edit_bones.remove(old)
        bone = rig.data.edit_bones.new(name)
        bone.head = (x, -0.40, 6.41)
        bone.tail = (x, -0.40, 6.51)
        bone.parent = head
    bpy.ops.object.mode_set(mode="OBJECT")


def _apply_world_transform(body: bpy.types.Object) -> None:
    shape_keys = body.data.shape_keys
    if shape_keys is None:
        for vertex in body.data.vertices:
            vertex.co = vertex.co * BODY_SCALE
            vertex.co.z += BODY_OFFSET_Z
        return
    # Object-level transform application is unreliable with an active stack of
    # absolute physique targets. Bake the exact same conversion into every key
    # so the basis, all milestones and the subsequently generated rig share one
    # coordinate system.
    for key in shape_keys.key_blocks:
        for point in key.data:
            point.co = point.co * BODY_SCALE
            # MakeHuman's front axis is opposite the existing GymRat scene.
            # Rotate around Z instead of mirroring so winding and normals stay
            # valid.
            point.co.x *= -1.0
            point.co.y *= -1.0
            point.co.z += BODY_OFFSET_Z


def _strip_macro_keys_and_add_physiques(
    body: bpy.types.Object,
    stage_coordinates: dict[int, list[Vector]],
) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    bpy.context.view_layer.objects.active = body
    if body.data.shape_keys is not None:
        bpy.ops.object.shape_key_remove(all=True, apply_mix=True)
    basis = body.shape_key_add(name="Basis")
    if len(basis.data) != len(next(iter(stage_coordinates.values()))):
        raise RuntimeError("MPFB physique coordinates no longer match the body")
    for level, coordinates in stage_coordinates.items():
        key = body.shape_key_add(name=f"PHYSIQUE_{level:03d}")
        for index, coordinate in enumerate(coordinates):
            key.data[index].co = coordinate
        key.value = 1.0 if level == min(stage_coordinates) else 0.0
    body["gymrat_physique_driver"] = True


def _remove_non_body_geometry(body: bpy.types.Object) -> None:
    """Remove MPFB helper/proxy surfaces from every physique shape key."""
    body_group = body.vertex_groups.get("body")
    if body_group is None:
        raise RuntimeError("MPFB body vertex group is missing")
    group_names = {group.index: group.name.lower() for group in body.vertex_groups}
    for vertex in body.data.vertices:
        belongs_to_body = any(
            membership.group == body_group.index and membership.weight > 0.01
            for membership in vertex.groups
        )
        belongs_to_human_hand = any(
            membership.weight > 0.12
            and any(
                token in group_names.get(membership.group, "")
                for token in ("hand", "finger", "thumb")
            )
            for membership in vertex.groups
        )
        vertex.select = not belongs_to_body or belongs_to_human_hand
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    bpy.context.view_layer.objects.active = body
    body.active_shape_key_index = 0
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.delete(type="VERT")
    bpy.ops.object.mode_set(mode="OBJECT")
    for modifier in tuple(body.modifiers):
        if modifier.type == "MASK":
            body.modifiers.remove(modifier)


def _apply_olympia_overdrives(
    body: bpy.types.Object,
    rig: bpy.types.Object,
    stages: list[int],
) -> None:
    for level in stages:
        key = body.data.shape_keys.key_blocks[f"PHYSIQUE_{level:03d}"]
        _olympia_overdrive(body, rig, key, STAGE_PROGRESS[level])


def _olympia_overdrive(
    body: bpy.types.Object,
    rig: bpy.types.Object,
    key: bpy.types.ShapeKey,
    progress: float,
) -> None:
    """Extrapolate MPFB's real muscle forms only for champion stages."""
    amount = _smoothstep(0.47, 1.0, progress)
    if amount <= 0:
        return
    group_names = {group.index: group.name for group in body.vertex_groups}
    regions = {
        "upper_arm.L": (0.24, 0.05, 0.45, 0.92),
        "upper_arm.R": (0.24, 0.05, 0.45, 0.92),
        "forearm.L": (0.14, 0.04, 0.34, 0.85),
        "forearm.R": (0.14, 0.04, 0.34, 0.85),
        "thigh.L": (0.20, 0.12, 0.52, 0.91),
        "thigh.R": (0.20, 0.12, 0.52, 0.91),
        "shin.L": (0.18, 0.04, 0.30, 0.76),
        "shin.R": (0.18, 0.04, 0.30, 0.76),
    }
    for index, point in enumerate(key.data):
        coordinate = point.co.copy()
        for membership in body.data.vertices[index].groups:
            name = group_names.get(membership.group, "")
            if name not in regions or membership.weight < 0.04:
                continue
            amplitude, start, peak, end = regions[name]
            bone = rig.data.bones[name]
            head = Vector(bone.head_local)
            axis = Vector(bone.tail_local) - head
            fraction = max(
                0.0,
                min(
                    1.0,
                    (coordinate - head).dot(axis)
                    / max(0.0001, axis.length_squared),
                ),
            )
            radial = coordinate - (head + axis * fraction)
            if radial.length > 0.0001:
                coordinate += (
                    radial.normalized()
                    * amplitude
                    * _bell(fraction, start, peak, end)
                    * amount
                    * membership.weight
                )
        z = coordinate.z
        if 3.90 < z < 5.55:
            side = 1.0 if coordinate.x >= 0 else -1.0
            lat = _bell(z, 3.90, 4.76, 5.52) * _smoothstep(
                0.30, 1.02, abs(coordinate.x)
            )
            coordinate.x += side * 0.25 * lat * amount
            if coordinate.y < -0.04:
                pec = _bell(z, 4.55, 5.02, 5.48) * _bell(
                    abs(coordinate.x), 0.08, 0.50, 1.14
                )
                coordinate.y -= 0.21 * pec * amount
        point.co = coordinate


def _set_stage(body: bpy.types.Object, stages: list[int], stage: int) -> None:
    selected = max((level for level in stages if level <= stage), default=stages[0])
    for level in stages:
        body.data.shape_keys.key_blocks[f"PHYSIQUE_{level:03d}"].value = (
            1.0 if level == selected else 0.0
        )


def _style_body(body: bpy.types.Object, identity: str) -> None:
    fur = _physical_material(
        "MAT_MH_FUR", (0.045, 0.024, 0.016, 1.0), fur_bump=True
    )
    cloth = _physical_material(
        "MAT_MH_CLOTH", (0.003, 0.004, 0.005, 1.0), roughness=0.91
    )
    skin = _physical_material(
        "MAT_MH_SKIN", (0.54, 0.18, 0.15, 1.0), roughness=0.56
    )
    hidden = _physical_material("MAT_MH_HIDDEN", (0.0, 0.0, 0.0, 0.0))
    hidden.node_tree.nodes["Principled BSDF"].inputs["Alpha"].default_value = 0.0
    hidden.surface_render_method = "DITHERED"
    body.data.materials.clear()
    for material in (fur, cloth, skin, hidden):
        body.data.materials.append(material)
    basis = body.data.shape_keys.key_blocks["Basis"]
    group_names = {group.index: group.name.lower() for group in body.vertex_groups}
    for polygon in body.data.polygons:
        center = sum(
            (basis.data[index].co for index in polygon.vertices), Vector()
        ) / len(polygon.vertices)
        hand_weight = max(
            (
                membership.weight
                for vertex_index in polygon.vertices
                for membership in body.data.vertices[vertex_index].groups
                if any(
                    token in group_names.get(membership.group, "")
                    for token in ("hand", "finger", "thumb")
                )
            ),
            default=0.0,
        )
        if hand_weight > 0.18:
            polygon.material_index = 3
        elif center.z > 5.82 and abs(center.x) < 0.72:
            polygon.material_index = 3
        elif 2.58 < center.z < 3.58:
            polygon.material_index = 1
        elif center.z < 0.30:
            polygon.material_index = 2
        elif identity == "female" and 4.40 < center.z < 5.45:
            polygon.material_index = 1
        elif identity == "non_binary" and 4.05 < center.z < 5.90:
            polygon.material_index = 1
        else:
            polygon.material_index = 0
        polygon.use_smooth = True


def _author_motion(
    repo_root: Path,
    rig: bpy.types.Object,
    manifest: dict[str, object],
    motion: str,
    view: str,
) -> None:
    sys.path.insert(0, str(repo_root / "tool/character_pipeline"))
    from author_motion_library import _author_emote, _author_simple

    if motion in manifest["emote_contract"]["types"]:
        _author_emote(
            rig,
            motion,
            view,
            manifest["motions"][motion],
            manifest["emote_contract"]["pose_specs"][motion],
        )
        name = f"ACT_{view}_{motion}"
    else:
        _author_simple(rig, motion, manifest["motions"][motion])
        name = f"ACT_{motion}"
    rig.animation_data_create()
    rig.animation_data.action = bpy.data.actions[name]


def main() -> None:
    args = _arguments()
    repo_root = args.repo_root.resolve()
    source_root = args.source_root.resolve()
    manifest = json.loads(
        (repo_root / "tool/character_pipeline/pipeline_manifest.json").read_text(
            encoding="utf-8"
        )
    )
    if args.stage not in manifest["stages"]:
        raise ValueError(f"Unsupported stage: {args.stage}")

    scene_path = source_root / "scenes" / f"{args.identity}_character.blend"
    bpy.ops.wm.open_mainfile(filepath=str(scene_path))
    model = bpy.data.collections.get("MODEL_AUTHORED")
    rig_collection = bpy.data.collections.get("RIG")
    if model is None or rig_collection is None:
        raise RuntimeError("GymRat scene collections are missing")
    _clear_collection(model)
    _clear_collection(rig_collection)

    human_service = _mpfb_service("mpfb.services.humanservice", "HumanService")
    target_service = _mpfb_service("mpfb.services.targetservice", "TargetService")
    body, stage_coordinates = _build_stage_coordinates(
        args.identity,
        manifest["stages"],
        human_service,
        target_service,
    )
    _strip_macro_keys_and_add_physiques(body, stage_coordinates)
    _apply_world_transform(body)
    rig = human_service.add_builtin_rig(body, "game_engine")
    if rig is None:
        raise RuntimeError("MPFB failed to create the game-engine rig")
    _rename_rig(rig, body)
    _remove_non_body_geometry(body)
    _add_face_motion_bones(rig)
    _add_tail_bones(rig, manifest["anatomy_contract"]["tail_anchor"])
    _apply_olympia_overdrives(body, rig, manifest["stages"])
    _set_stage(body, manifest["stages"], args.stage)

    _move_to_collection(body, model)
    _move_to_collection(rig, rig_collection)
    body.name = "BODY_GYMRAT_ANATOMICAL"
    _style_body(body, args.identity)

    front_image = bpy.data.objects["REF_FRONT"].data
    back_image = bpy.data.objects["REF_BACK"].data
    _build_master_shell(
        "HEAD_GYMRAT_FRONT",
        front_image,
        rig,
        model,
        view="front",
        minimum_z=5.38,
    )
    _build_master_shell(
        "HEAD_GYMRAT_BACK",
        back_image,
        rig,
        model,
        view="back",
        minimum_z=5.38,
    )
    _add_fist_coverage(
        model,
        rig,
        front_image,
        back_image,
        (0.18, 0.10, 0.075, 1.0),
    )
    _add_tail_mesh(
        model,
        rig,
        front_image,
        back_image,
        (0.50, 0.20, 0.16, 1.0),
    )
    tail = bpy.data.objects["BODY_TAIL"]
    tail.data.materials.clear()
    tail.data.materials.append(
        _physical_material("MAT_MH_TAIL", (0.48, 0.16, 0.13, 1.0), roughness=0.58)
    )

    rig["gymrat_rig_contract"] = 2
    rig["gymrat_tail_anchor_contract"] = json.dumps(
        manifest["anatomy_contract"]["tail_anchor"]
    )
    model["gymrat_model_status"] = "mpfb_cc0_anatomy_identity_pilot"
    model["gymrat_topology_source"] = "MakeHuman Community MPFB 2"
    model["gymrat_topology_license"] = "CC0-1.0"
    bpy.context.scene["gymrat_model_review_required"] = True

    if args.motion is not None:
        _author_motion(repo_root, rig, manifest, args.motion, args.view)
    bpy.context.scene.frame_set(args.frame)
    selected_key = body.data.shape_keys.key_blocks[f"PHYSIQUE_{args.stage:03d}"]
    print(
        "MPFB body bounds:",
        {
            "basis_z": (
                round(min(point.co.z for point in body.data.shape_keys.key_blocks["Basis"].data), 3),
                round(max(point.co.z for point in body.data.shape_keys.key_blocks["Basis"].data), 3),
            ),
            "stage_z": (
                round(min(point.co.z for point in selected_key.data), 3),
                round(max(point.co.z for point in selected_key.data), 3),
            ),
            "object_scale": tuple(round(value, 3) for value in body.scale),
            "parent": body.parent.name if body.parent is not None else None,
        },
    )
    if args.render_preview is not None:
        _preview(args.render_preview.resolve(), args.view)
    if args.dry_run:
        print(f"Built {args.identity} MPFB anatomy pilot without saving")
        return
    bpy.ops.wm.save_as_mainfile(filepath=str(scene_path))
    print(f"Built {args.identity} MPFB anatomy pilot in {scene_path}")


if __name__ == "__main__":
    try:
        main()
    except Exception:
        traceback.print_exc()
        raise SystemExit(1)
