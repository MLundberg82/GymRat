#!/usr/bin/env python3
"""Create reproducible Blender source scenes from the approved masters."""

from __future__ import annotations

import argparse
import hashlib
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
    parser.add_argument(
        "--identity",
        choices=("male", "female", "non_binary"),
        action="append",
    )
    return parser.parse_args(argv)


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _collection(name: str) -> bpy.types.Collection:
    collection = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(collection)
    return collection


def _move_to_collection(
    obj: bpy.types.Object, collection: bpy.types.Collection
) -> None:
    for owner in tuple(obj.users_collection):
        owner.objects.unlink(obj)
    collection.objects.link(obj)


def _reference(
    name: str,
    path: Path,
    location: tuple[float, float, float],
    rotation: tuple[float, float, float],
    collection: bpy.types.Collection,
) -> bpy.types.Object:
    image = bpy.data.images.load(str(path), check_existing=False)
    image.name = f"{name}_IMAGE"
    bpy.ops.object.empty_add(type="IMAGE", location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data = image
    _move_to_collection(obj, collection)
    obj.empty_display_size = 7.25
    obj.color[3] = 0.48
    obj.show_in_front = True
    obj.hide_render = True
    obj["gymrat_source_sha256"] = _sha256(path)
    return obj


def _camera(
    name: str,
    location: tuple[float, float, float],
    rotation: tuple[float, float, float],
    collection: bpy.types.Collection,
) -> bpy.types.Object:
    data = bpy.data.cameras.new(name)
    data.type = "ORTHO"
    data.ortho_scale = 9.4
    obj = bpy.data.objects.new(name, data)
    obj.location = location
    obj.rotation_euler = rotation
    collection.objects.link(obj)
    return obj


def _bone(
    armature: bpy.types.Armature,
    name: str,
    head: tuple[float, float, float],
    tail: tuple[float, float, float],
    parent: bpy.types.EditBone | None = None,
) -> bpy.types.EditBone:
    bone = armature.edit_bones.new(name)
    bone.head = head
    bone.tail = tail
    bone.parent = parent
    return bone


def _rig(
    collection: bpy.types.Collection,
    anatomy_contract: dict[str, object],
) -> bpy.types.Object:
    bpy.ops.object.armature_add(enter_editmode=True, location=(0, 0, 0))
    rig = bpy.context.object
    rig.name = "RIG_GYMRAT"
    _move_to_collection(rig, collection)
    armature = rig.data
    armature.name = "RIG_GYMRAT_DATA"
    armature.edit_bones.remove(armature.edit_bones[0])

    root = _bone(armature, "root", (0, 0, 0), (0, 0, 0.35))
    pelvis = _bone(armature, "pelvis", (0, 0, 2.8), (0, 0, 3.4), root)
    spine_1 = _bone(armature, "spine_01", (0, 0, 3.4), (0, 0, 4.1), pelvis)
    spine_2 = _bone(armature, "spine_02", (0, 0, 4.1), (0, 0, 4.9), spine_1)
    chest = _bone(armature, "chest", (0, 0, 4.9), (0, 0, 5.55), spine_2)
    neck = _bone(armature, "neck", (0, 0, 5.55), (0, 0, 6.0), chest)
    head = _bone(armature, "head", (0, 0, 6.0), (0, 0, 6.85), neck)
    _bone(armature, "jaw", (0, -0.08, 6.35), (0, -0.36, 6.12), head)
    _bone(armature, "ear.L", (0.23, 0, 6.62), (0.58, 0, 7.23), head)
    _bone(armature, "ear.R", (-0.23, 0, 6.62), (-0.58, 0, 7.23), head)
    _bone(armature, "eyelid.L", (0.2, -0.1, 6.52), (0.2, -0.3, 6.52), head)
    _bone(armature, "eyelid.R", (-0.2, -0.1, 6.52), (-0.2, -0.3, 6.52), head)

    for side, sign in (("L", 1.0), ("R", -1.0)):
        clavicle = _bone(
            armature,
            f"clavicle.{side}",
            (0, 0, 5.35),
            (0.58 * sign, 0, 5.35),
            chest,
        )
        upper_arm = _bone(
            armature,
            f"upper_arm.{side}",
            (0.58 * sign, 0, 5.35),
            (1.2 * sign, 0, 4.55),
            clavicle,
        )
        forearm = _bone(
            armature,
            f"forearm.{side}",
            (1.2 * sign, 0, 4.55),
            (1.45 * sign, 0, 3.72),
            upper_arm,
        )
        _bone(
            armature,
            f"hand.{side}",
            (1.45 * sign, 0, 3.72),
            (1.5 * sign, 0, 3.25),
            forearm,
        )
        thigh = _bone(
            armature,
            f"thigh.{side}",
            (0.42 * sign, 0, 3.0),
            (0.53 * sign, 0, 1.72),
            pelvis,
        )
        shin = _bone(
            armature,
            f"shin.{side}",
            (0.53 * sign, 0, 1.72),
            (0.48 * sign, 0, 0.58),
            thigh,
        )
        _bone(
            armature,
            f"foot.{side}",
            (0.48 * sign, 0, 0.58),
            (0.48 * sign, -0.55, 0.12),
            shin,
        )

    tail_anchor = anatomy_contract["tail_anchor"]
    tail_parent = _bone(
        armature,
        str(tail_anchor["bone"]),
        tuple(float(value) for value in tail_anchor["head"]),
        tuple(float(value) for value in tail_anchor["tail"]),
        pelvis,
    )
    for index in range(10):
        x = index * 0.30
        z = 3.12 - index * 0.10
        tail_parent = _bone(
            armature,
            f"tail_{index + 1:02d}",
            (x, 0.42, z),
            (x + 0.30, 0.42, z - 0.10),
            tail_parent,
        )

    bpy.ops.object.mode_set(mode="OBJECT")
    rig.show_in_front = True
    rig["gymrat_rig_contract"] = 1
    rig["gymrat_tail_anchor_contract"] = json.dumps(tail_anchor)
    return rig


def _actions(manifest: dict[str, object]) -> None:
    for name, definition in manifest["motions"].items():
        action = bpy.data.actions.new(name=f"ACT_{name}")
        action.use_fake_user = True
        action["gymrat_frames"] = int(definition["frames"])
        action["gymrat_loop"] = bool(definition["loop"])


def _configure_scene(
    identity: str,
    repo_root: Path,
    source_root: Path,
    manifest: dict[str, object],
) -> Path:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.name = f"GymRat_{identity}"
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = int(manifest["canvas"]["width"])
    scene.render.resolution_y = int(manifest["canvas"]["height"])
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.film_transparent = True
    scene.render.fps = int(manifest["canvas"]["frame_rate"])
    world = bpy.data.worlds.new("GymRatWorld")
    world.color = (0.008, 0.01, 0.009)
    scene.world = world
    scene["gymrat_pipeline_version"] = int(manifest["version"])
    scene["gymrat_identity"] = identity
    scene["gymrat_stages"] = json.dumps(manifest["stages"])
    scene["gymrat_release_contract"] = json.dumps(manifest["release_contract"])
    scene["gymrat_anatomy_contract"] = json.dumps(manifest["anatomy_contract"])

    references = _collection("REFERENCES_LOCKED")
    model = _collection("MODEL_AUTHORED")
    rig_collection = _collection("RIG")
    cameras = _collection("CAMERAS")
    _collection("LIGHTS")
    model["gymrat_required_shape_keys"] = json.dumps(
        [f"PHYSIQUE_{level:03d}" for level in manifest["stages"]]
    )

    identity_manifest = manifest["identities"][identity]
    front = (repo_root / identity_manifest["front_master"]).resolve()
    back = (repo_root / identity_manifest["back_master"]).resolve()
    if not front.is_file() or not back.is_file():
        raise FileNotFoundError(f"Missing approved masters for {identity}")

    _reference(
        "REF_FRONT",
        front,
        (0, 0.8, 3.7),
        (math.pi / 2, 0, 0),
        references,
    )
    _reference(
        "REF_BACK",
        back,
        (0, -0.8, 3.7),
        (math.pi / 2, 0, math.pi),
        references,
    )

    approvals_path = source_root / "approvals.json"
    if approvals_path.is_file():
        approvals = json.loads(approvals_path.read_text(encoding="utf-8"))
        approval = approvals.get(f"{identity}_level_100_front_direction")
        if approval is not None:
            direction = (source_root / approval["file"]).resolve()
            if _sha256(direction) != approval["sha256"]:
                raise ValueError(
                    f"Approved level-100 direction checksum drifted: {identity}"
                )
            direction_reference = _reference(
                "REF_LEVEL_100_FRONT_DIRECTION",
                direction,
                (4.4, 0.8, 3.7),
                (math.pi / 2, 0, 0),
                references,
            )
            direction_reference["gymrat_approval_status"] = approval["status"]
            scene["gymrat_level_100_front_direction_sha256"] = approval[
                "sha256"
            ]
    front_camera = _camera(
        "CAM_FRONT",
        (0, -12, 3.7),
        (math.pi / 2, 0, 0),
        cameras,
    )
    _camera(
        "CAM_BACK",
        (0, 12, 3.7),
        (math.pi / 2, 0, math.pi),
        cameras,
    )
    scene.camera = front_camera
    _rig(rig_collection, manifest["anatomy_contract"])
    _actions(manifest)

    scene_path = source_root / "scenes" / f"{identity}_character.blend"
    scene_path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(scene_path))
    return scene_path


def main() -> None:
    args = _arguments()
    repo_root = args.repo_root.resolve()
    source_root = args.source_root.resolve()
    manifest_path = repo_root / "tool/character_pipeline/pipeline_manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    identities = args.identity or tuple(manifest["identities"])
    source_root.mkdir(parents=True, exist_ok=True)

    checksums: dict[str, dict[str, str]] = {}
    for identity in identities:
        definition = manifest["identities"][identity]
        checksums[identity] = {
            view: _sha256(repo_root / definition[f"{view}_master"])
            for view in manifest["release_contract"]["views"]
        }
        scene_path = _configure_scene(
            identity, repo_root, source_root, manifest
        )
        print(f"Created {scene_path}")

    checksum_path = source_root / "master_checksums.json"
    checksum_path.write_text(
        json.dumps(checksums, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(f"Wrote {checksum_path}")


if __name__ == "__main__":
    main()
