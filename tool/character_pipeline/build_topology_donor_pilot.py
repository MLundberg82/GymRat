#!/usr/bin/env python3
"""Build a review-only GymRat model from a verified CC0 topology donor.

The script never invents a replacement identity. It reshapes a reusable body
topology against the approved front/back master, projects only those locked
masters, adds the GymRat tail contract, and authors real milestone shape keys.
The resulting scene remains review-gated and cannot be exported to runtime.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import sys
import traceback
from array import array
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector


IDENTITIES = ("male", "female", "non_binary")
CANVAS_WIDTH = 1024
CANVAS_HEIGHT = 1792
CANVAS_WORLD_HEIGHT = 7.25
CANVAS_WORLD_WIDTH = CANVAS_WORLD_HEIGHT * CANVAS_WIDTH / CANVAS_HEIGHT
CANVAS_WORLD_BOTTOM = 3.7 - CANVAS_WORLD_HEIGHT / 2
DONOR_OBJECT = "Mast2024-11"
DONOR_RIG = "ArmatureMast"

BONE_MAP = {
    "Raiz": "root",
    "Root": "pelvis",
    "Spine01": "spine_01",
    "Spine02": "spine_02",
    "Spine03": "chest",
    "Spine04": "neck",
    "Spine05": "head_base",
    "Head": "head",
    "Ombro.L": "clavicle.L",
    "Ombro.R": "clavicle.R",
    "Braço01.L": "upper_arm.L",
    "Braço01.R": "upper_arm.R",
    "Braço02.L": "forearm.L",
    "Braço02.R": "forearm.R",
    "Pulso.L": "hand.L",
    "Pulso.R": "hand.R",
    "Leg01.L": "thigh.L",
    "Leg01.R": "thigh.R",
    "Leg02.L": "shin.L",
    "Leg02.R": "shin.R",
    "Foot.L": "foot.L",
    "Foot.R": "foot.R",
    "EyelidUpper.L": "eyelid.L",
    "EyelidUpper.R": "eyelid.R",
}

MUSCLE_GAINS = {
    "chest": 0.62,
    "spine_02": 0.34,
    "upper_arm.L": 0.68,
    "upper_arm.R": 0.68,
    "forearm.L": 0.48,
    "forearm.R": 0.48,
    "thigh.L": 0.56,
    "thigh.R": 0.56,
    "shin.L": 0.43,
    "shin.R": 0.43,
}

# Visual progression is authored per milestone instead of derived from the
# numeric level. This gives level 5 a readable first reward while reserving the
# largest changes for the late Olympia stages.
STAGE_PROGRESS = {
    1: 0.00,
    5: 0.07,
    10: 0.14,
    15: 0.22,
    20: 0.31,
    30: 0.42,
    40: 0.53,
    50: 0.64,
    60: 0.73,
    70: 0.81,
    80: 0.88,
    90: 0.94,
    100: 1.00,
}


def _arguments() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, required=True)
    parser.add_argument("--source-root", type=Path, required=True)
    parser.add_argument("--identity", choices=IDENTITIES, required=True)
    parser.add_argument("--render-preview", type=Path)
    parser.add_argument("--view", choices=("front", "back"), default="front")
    parser.add_argument("--stage", type=int, default=1)
    parser.add_argument("--motion")
    parser.add_argument("--frame", type=int, default=1)
    parser.add_argument(
        "--geometry", choices=("shell", "donor", "procedural"), default="shell"
    )
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args(argv)


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _move_to_collection(
    obj: bpy.types.Object, collection: bpy.types.Collection
) -> None:
    for owner in tuple(obj.users_collection):
        owner.objects.unlink(obj)
    collection.objects.link(obj)


def _clear_collection(collection: bpy.types.Collection) -> None:
    for obj in tuple(collection.objects):
        bpy.data.objects.remove(obj, do_unlink=True)


def _load_donor(path: Path) -> tuple[bpy.types.Object, bpy.types.Object]:
    with bpy.data.libraries.load(str(path), link=False) as (available, loaded):
        required = {DONOR_OBJECT, DONOR_RIG}
        missing = required.difference(available.objects)
        if missing:
            raise RuntimeError(f"Topology donor is missing: {sorted(missing)}")
        loaded.objects = [DONOR_OBJECT, DONOR_RIG]
    objects = {obj.name: obj for obj in loaded.objects if obj is not None}
    return objects[DONOR_OBJECT], objects[DONOR_RIG]


def _apply_transform(obj: bpy.types.Object) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


def _prepare_donor(
    mesh: bpy.types.Object,
    rig: bpy.types.Object,
    model_collection: bpy.types.Collection,
    rig_collection: bpy.types.Collection,
) -> None:
    _move_to_collection(mesh, model_collection)
    _move_to_collection(rig, rig_collection)
    for pose_bone in rig.pose.bones:
        for constraint in tuple(pose_bone.constraints):
            pose_bone.constraints.remove(constraint)

    _lower_donor_arms(mesh, rig)
    scale = 4.08
    offset = Vector((0.0, 0.0, 0.10))
    for vertex in mesh.data.vertices:
        vertex.co = vertex.co * scale + offset
    bone_coordinates = {
        bone.name: (Vector(bone.head_local), Vector(bone.tail_local))
        for bone in rig.data.bones
    }
    bpy.context.view_layer.objects.active = rig
    rig.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    for bone in rig.data.edit_bones:
        bone.use_connect = False
    for bone in rig.data.edit_bones:
        head, tail = bone_coordinates[bone.name]
        bone.head = head * scale + offset
        bone.tail = tail * scale + offset
    bpy.ops.object.mode_set(mode="OBJECT")

    for modifier in tuple(mesh.modifiers):
        if modifier.type == "SUBSURF":
            modifier.levels = 1
            modifier.render_levels = 1
        elif modifier.type not in {"ARMATURE", "MASK"}:
            mesh.modifiers.remove(modifier)


def _lower_donor_arms(mesh: bpy.types.Object, rig: bpy.types.Object) -> None:
    """Rotate donor arm topology into the approved neutral silhouette."""
    group_names = {group.index: group.name for group in mesh.vertex_groups}
    arm_contracts: list[tuple[Vector, float, set[str]]] = []
    for side, sign in (("L", 1.0), ("R", -1.0)):
        upper = rig.data.bones[f"Braço01.{side}"]
        names = {upper.name, *(bone.name for bone in upper.children_recursive)}
        arm_contracts.append((Vector(upper.head_local), math.radians(39) * sign, names))

    for vertex in mesh.data.vertices:
        original = vertex.co.copy()
        for pivot, angle, names in arm_contracts:
            weight = max(
                (
                    membership.weight
                    for membership in vertex.groups
                    if group_names.get(membership.group) in names
                ),
                default=0.0,
            )
            if weight <= 0:
                continue
            rotation = Matrix.Rotation(angle * weight, 4, "Y")
            vertex.co = pivot + rotation @ (original - pivot)
            break

    bone_coordinates = {
        bone.name: (Vector(bone.head_local), Vector(bone.tail_local))
        for bone in rig.data.bones
    }
    arm_bones = {
        side: {
            rig.data.bones[f"Braço01.{side}"].name,
            *(
                bone.name
                for bone in rig.data.bones[f"Braço01.{side}"].children_recursive
            ),
        }
        for side in ("L", "R")
    }
    bpy.context.view_layer.objects.active = rig
    rig.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    for bone in rig.data.edit_bones:
        bone.use_connect = False
    for side, sign in (("L", 1.0), ("R", -1.0)):
        pivot = bone_coordinates[f"Braço01.{side}"][0]
        rotation = Matrix.Rotation(math.radians(39) * sign, 4, "Y")
        for name in arm_bones[side]:
            bone = rig.data.edit_bones.get(name)
            if bone is None:
                continue
            head, tail = bone_coordinates[name]
            bone.head = pivot + rotation @ (head - pivot)
            bone.tail = pivot + rotation @ (tail - pivot)
    bpy.ops.object.mode_set(mode="OBJECT")
    _remove_open_fingers(mesh)


def _remove_open_fingers(mesh: bpy.types.Object) -> None:
    """Remove donor finger fans; projected GymRat fist coverage replaces them."""
    group_names = {group.index: group.name for group in mesh.vertex_groups}
    remove = {
        vertex.index
        for vertex in mesh.data.vertices
        if any(
            group_names.get(membership.group, "").startswith("Phinger")
            and membership.weight > 0.08
            for membership in vertex.groups
        )
    }
    if not remove:
        return
    bm = bmesh.new()
    bm.from_mesh(mesh.data)
    bm.verts.ensure_lookup_table()
    bmesh.ops.delete(
        bm,
        geom=[bm.verts[index] for index in remove],
        context="VERTS",
    )
    bm.to_mesh(mesh.data)
    bm.free()
    mesh.data.update()


def _rename_contract_bones(mesh: bpy.types.Object, rig: bpy.types.Object) -> None:
    for old_name, new_name in BONE_MAP.items():
        bone = rig.data.bones.get(old_name)
        if bone is not None:
            bone.name = new_name
        group = mesh.vertex_groups.get(old_name)
        if group is not None:
            group.name = new_name
    rig.name = "RIG_GYMRAT"
    rig.data.name = "RIG_GYMRAT_DATA"


def _master_profile(image: bpy.types.Image) -> list[float]:
    if image.size[0] != CANVAS_WIDTH or image.size[1] != CANVAS_HEIGHT:
        raise RuntimeError(f"Unexpected master size: {tuple(image.size)}")
    pixels = array("f", [0.0]) * (CANVAS_WIDTH * CANVAS_HEIGHT * 4)
    image.pixels.foreach_get(pixels)
    profile: list[float] = []
    center = CANVAS_WIDTH // 2
    for sample in range(256):
        y = round(sample / 255 * (CANVAS_HEIGHT - 1))
        occupied: list[int] = []
        for x in range(CANVAS_WIDTH):
            coverage = 0.0
            for offset in range(-3, 4):
                row = max(0, min(CANVAS_HEIGHT - 1, y + offset))
                coverage += pixels[(row * CANVAS_WIDTH + x) * 4 + 3]
            if coverage >= 2.2:
                occupied.append(x)
        if not occupied:
            profile.append(0.0)
            continue
        left = center - min(occupied)
        right = max(occupied) - center
        symmetric = max(4.0, min(float(left), float(right)))
        profile.append(symmetric / CANVAS_WIDTH * CANVAS_WORLD_WIDTH)
    return _smooth_profile(profile)


def _smooth_profile(values: list[float]) -> list[float]:
    result: list[float] = []
    for index in range(len(values)):
        window = [
            values[position]
            for position in range(max(0, index - 3), min(len(values), index + 4))
            if values[position] > 0
        ]
        result.append(sum(window) / len(window) if window else 0.0)
    return result


def _sample_profile(profile: list[float], z: float) -> float:
    normalized = max(
        0.0, min(1.0, (z - CANVAS_WORLD_BOTTOM) / CANVAS_WORLD_HEIGHT)
    )
    position = normalized * (len(profile) - 1)
    lower = int(math.floor(position))
    upper = min(len(profile) - 1, lower + 1)
    mix = position - lower
    return profile[lower] * (1 - mix) + profile[upper] * mix


def _fit_mesh_to_master(mesh: bpy.types.Object, profile: list[float]) -> None:
    vertices = mesh.data.vertices
    minimum_z = min(vertex.co.z for vertex in vertices)
    maximum_z = max(vertex.co.z for vertex in vertices)
    source_bins = [0.0] * len(profile)
    for vertex in vertices:
        normalized = (vertex.co.z - minimum_z) / max(0.001, maximum_z - minimum_z)
        index = min(len(profile) - 1, max(0, round(normalized * (len(profile) - 1))))
        source_bins[index] = max(source_bins[index], abs(vertex.co.x))
    source_bins = _smooth_profile(source_bins)

    target_bottom = CANVAS_WORLD_BOTTOM + 0.10
    target_top = CANVAS_WORLD_BOTTOM + CANVAS_WORLD_HEIGHT * 0.965
    for vertex in vertices:
        normalized = (vertex.co.z - minimum_z) / max(0.001, maximum_z - minimum_z)
        target_z = target_bottom + normalized * (target_top - target_bottom)
        index = min(len(profile) - 1, max(0, round(normalized * (len(profile) - 1))))
        target_half = _sample_profile(profile, target_z)
        source_half = max(0.08, source_bins[index])
        width_scale = max(0.18, min(1.65, target_half / source_half))
        vertex.co.x *= width_scale
        vertex.co.y *= 0.88 + width_scale * 0.12
        vertex.co.z = target_z


def _reshape_contract_rig(rig: bpy.types.Object, mesh: bpy.types.Object) -> None:
    minimum_z = min(vertex.co.z for vertex in mesh.data.vertices)
    maximum_z = max(vertex.co.z for vertex in mesh.data.vertices)
    bpy.context.view_layer.objects.active = rig
    rig.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    for bone in rig.data.edit_bones:
        for point in (bone.head, bone.tail):
            point.z = max(minimum_z, min(maximum_z, point.z))
    bpy.ops.object.mode_set(mode="OBJECT")


def _project_uv(obj: bpy.types.Object) -> None:
    for layer_name in ("GymRatFrontUV", "GymRatBackUV"):
        existing = obj.data.uv_layers.get(layer_name)
        if existing is not None:
            obj.data.uv_layers.remove(existing)
    front = obj.data.uv_layers.new(name="GymRatFrontUV")
    back = obj.data.uv_layers.new(name="GymRatBackUV")
    for polygon in obj.data.polygons:
        for loop_index in polygon.loop_indices:
            vertex = obj.data.vertices[obj.data.loops[loop_index].vertex_index]
            world = obj.matrix_world @ vertex.co
            u = (world.x + CANVAS_WORLD_WIDTH / 2) / CANVAS_WORLD_WIDTH
            v = (world.z - CANVAS_WORLD_BOTTOM) / CANVAS_WORLD_HEIGHT
            front.data[loop_index].uv = (u, v)
            back.data[loop_index].uv = (1 - u, v)


def _projected_material(
    name: str,
    image: bpy.types.Image,
    uv_name: str,
    fallback: tuple[float, float, float, float],
) -> bpy.types.Material:
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    nodes.clear()
    output = nodes.new("ShaderNodeOutputMaterial")
    shader = nodes.new("ShaderNodeBsdfPrincipled")
    shader.inputs["Roughness"].default_value = 0.78
    uv = nodes.new("ShaderNodeUVMap")
    uv.uv_map = uv_name
    texture = nodes.new("ShaderNodeTexImage")
    texture.image = image
    texture.interpolation = "Linear"
    texture.extension = "CLIP"
    links.new(uv.outputs["UV"], texture.inputs["Vector"])
    links.new(texture.outputs["Color"], shader.inputs["Base Color"])
    links.new(texture.outputs["Alpha"], shader.inputs["Alpha"])
    if "Emission Color" in shader.inputs:
        links.new(texture.outputs["Color"], shader.inputs["Emission Color"])
        shader.inputs["Emission Strength"].default_value = 0.16
    links.new(shader.outputs["BSDF"], output.inputs["Surface"])
    if hasattr(material, "surface_render_method"):
        material.surface_render_method = "DITHERED"
    return material


def _assign_master_materials(
    obj: bpy.types.Object,
    front_image: bpy.types.Image,
    back_image: bpy.types.Image,
    fallback: tuple[float, float, float, float],
) -> None:
    obj.data.materials.clear()
    obj.data.materials.append(
        _projected_material(
            f"MAT_{obj.name}_FRONT", front_image, "GymRatFrontUV", fallback
        )
    )
    obj.data.materials.append(
        _projected_material(
            f"MAT_{obj.name}_BACK", back_image, "GymRatBackUV", fallback
        )
    )
    for polygon in obj.data.polygons:
        polygon.material_index = 0 if polygon.normal.y < 0 else 1


def _pixel_sample(
    pixels: array, u: float, v: float
) -> tuple[float, float, float, float]:
    x = max(0, min(CANVAS_WIDTH - 1, round(u * (CANVAS_WIDTH - 1))))
    y = max(0, min(CANVAS_HEIGHT - 1, round(v * (CANVAS_HEIGHT - 1))))
    offset = (y * CANVAS_WIDTH + x) * 4
    return tuple(float(pixels[offset + channel]) for channel in range(4))


def _bone_weights(
    point: Vector,
    rig: bpy.types.Object,
    color: tuple[float, float, float, float],
    *,
    force_tail: bool = False,
) -> dict[str, float]:
    if force_tail:
        tail_names = [f"tail_{index:02d}" for index in range(1, 11)]
        name = min(
            tail_names,
            key=lambda name: _bone_distance_2d(point, rig.data.bones[name]),
        )
        return {name: 1.0}

    if point.z > 5.72 and abs(point.x) < 1.48:
        if 6.30 < point.z < 6.72 and 0.08 < abs(point.x) < 0.44:
            return {"eyelid.L" if point.x > 0 else "eyelid.R": 1.0}
        return {"head": 1.0}

    side = "L" if point.x >= 0 else "R"
    if point.z < 3.25:
        candidates = (
            "pelvis",
            "spine_01",
            f"thigh.{side}",
            f"shin.{side}",
            f"foot.{side}",
        )
    elif point.z < 5.72:
        candidates = (
            "pelvis",
            "spine_01",
            "spine_02",
            "chest",
            f"upper_arm.{side}",
            f"forearm.{side}",
            f"hand.{side}",
        )
    else:
        candidates = ("chest", "neck", "head")
    available = [name for name in candidates if rig.data.bones.get(name) is not None]
    distances = sorted(
        (
            (_bone_distance_2d(point, rig.data.bones[name]), name)
            for name in available
        ),
        key=lambda item: item[0],
    )[:3]
    raw = {name: 1 / ((distance + 0.09) ** 2) for distance, name in distances}
    total = sum(raw.values())
    return {name: value / total for name, value in raw.items()}


def _bone_distance_2d(point: Vector, bone: bpy.types.Bone) -> float:
    head = Vector((bone.head_local.x, 0.0, bone.head_local.z))
    tail = Vector((bone.tail_local.x, 0.0, bone.tail_local.z))
    sample = Vector((point.x, 0.0, point.z))
    axis = tail - head
    fraction = max(
        0.0,
        min(1.0, (sample - head).dot(axis) / max(0.0001, axis.length_squared)),
    )
    return (sample - (head + axis * fraction)).length


def _shell_material(
    name: str, image: bpy.types.Image, uv_name: str
) -> bpy.types.Material:
    material = _projected_material(name, image, uv_name, (0.0, 0.0, 0.0, 0.0))
    material.use_backface_culling = True
    return material


def _physical_material(
    name: str,
    color: tuple[float, float, float, float],
    *,
    roughness: float = 0.72,
    fur_bump: bool = False,
) -> bpy.types.Material:
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    shader = material.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = color
    shader.inputs["Roughness"].default_value = roughness
    if fur_bump:
        noise = material.node_tree.nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = 42.0
        noise.inputs["Detail"].default_value = 5.0
        noise.inputs["Roughness"].default_value = 0.78
        bump = material.node_tree.nodes.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = 0.22
        bump.inputs["Distance"].default_value = 0.045
        material.node_tree.links.new(noise.outputs["Fac"], bump.inputs["Height"])
        material.node_tree.links.new(bump.outputs["Normal"], shader.inputs["Normal"])
    return material


def _bind_part(
    obj: bpy.types.Object,
    rig: bpy.types.Object,
    bone_name: str,
    model: bpy.types.Collection,
) -> bpy.types.Object:
    _move_to_collection(obj, model)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    group = obj.vertex_groups.new(name=bone_name)
    group.add(range(len(obj.data.vertices)), 1.0, "REPLACE")
    modifier = obj.modifiers.new(name="GymRat Armature", type="ARMATURE")
    modifier.object = rig
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    return obj


def _sphere_part(
    name: str,
    location: tuple[float, float, float],
    scale: tuple[float, float, float],
    material: bpy.types.Material,
    rig: bpy.types.Object,
    bone_name: str,
    model: bpy.types.Collection,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=40,
        ring_count=28,
        location=location,
        scale=scale,
    )
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material)
    return _bind_part(obj, rig, bone_name, model)


def _style_procedural_character(
    mesh: bpy.types.Object,
    rig: bpy.types.Object,
    model: bpy.types.Collection,
    identity: str,
) -> None:
    fur = _physical_material("MAT_FUR", (0.022, 0.011, 0.006, 1.0), fur_bump=True)
    cloth = _physical_material("MAT_CLOTH", (0.002, 0.003, 0.004, 1.0), roughness=0.9)
    skin = _physical_material("MAT_SKIN", (0.55, 0.19, 0.16, 1.0), roughness=0.55)
    hidden = _physical_material("MAT_HIDDEN_HEAD", (0.0, 0.0, 0.0, 0.0))
    hidden.node_tree.nodes["Principled BSDF"].inputs["Alpha"].default_value = 0.0
    hidden.surface_render_method = "DITHERED"
    mesh.data.materials.clear()
    for material in (fur, fur, cloth, skin, hidden):
        mesh.data.materials.append(material)
    group_names = {group.index: group.name for group in mesh.vertex_groups}
    for polygon in mesh.data.polygons:
        center = sum((mesh.data.vertices[index].co for index in polygon.vertices), Vector()) / len(polygon.vertices)
        head_weight = sum(
            membership.weight
            for index in polygon.vertices
            for membership in mesh.data.vertices[index].groups
            if group_names.get(membership.group) in {"head", "head_base"}
        ) / len(polygon.vertices)
        if head_weight > 0.10 or (center.z > 5.72 and abs(center.x) < 0.62):
            polygon.material_index = 4
        elif 2.62 < center.z < 3.62:
            polygon.material_index = 2
        elif center.z < 0.42:
            polygon.material_index = 3
        else:
            polygon.material_index = 0

    if identity == "female":
        top_bottom, top_top = 4.42, 5.45
    elif identity == "non_binary":
        top_bottom, top_top = 4.10, 5.92
    else:
        top_bottom, top_top = 0.0, 0.0
    if top_top:
        for polygon in mesh.data.polygons:
            center_z = sum(mesh.data.vertices[index].co.z for index in polygon.vertices) / len(polygon.vertices)
            if top_bottom < center_z < top_top:
                polygon.material_index = 2

    for side in ("L", "R"):
        hand_bone = f"hand.{side}"
        hand = rig.data.bones[hand_bone]
        hand_center = Vector(hand.head_local).lerp(Vector(hand.tail_local), 0.55)
        _sphere_part(
            f"PAW_{side}",
            tuple(hand_center),
            (0.27, 0.22, 0.32),
            fur,
            rig,
            hand_bone,
            model,
        )


def _build_master_shell(
    name: str,
    image: bpy.types.Image,
    rig: bpy.types.Object,
    model: bpy.types.Collection,
    *,
    view: str,
    minimum_z: float | None = None,
) -> bpy.types.Object:
    columns = 96
    rows = 168
    pixels = array("f", [0.0]) * (CANVAS_WIDTH * CANVAS_HEIGHT * 4)
    image.pixels.foreach_get(pixels)
    vertex_map: dict[tuple[bool, int, int], int] = {}
    vertices: list[tuple[float, float, float]] = []
    uv_values: list[tuple[float, float]] = []
    vertex_weights: list[dict[str, float]] = []
    faces: list[tuple[int, int, int, int]] = []

    def is_tail_sample(u: float, v: float) -> bool:
        top_v = 1.0 - v
        if view == "front":
            path = (
                (0.77, 0.55),
                (0.85, 0.58),
                (0.91, 0.62),
                (0.92, 0.66),
                (0.88, 0.69),
                (0.81, 0.70),
                (0.74, 0.69),
                (0.69, 0.66),
            )
            radius = 0.046
        else:
            path = (
                (0.50, 0.45),
                (0.50, 0.55),
                (0.48, 0.63),
                (0.43, 0.70),
                (0.35, 0.75),
                (0.25, 0.77),
                (0.16, 0.75),
                (0.11, 0.71),
                (0.11, 0.67),
                (0.15, 0.64),
            )
            radius = 0.040
        sample = Vector((u, top_v))
        shortest = float("inf")
        for start, end in zip(path, path[1:]):
            segment_start = Vector(start)
            axis = Vector(end) - segment_start
            fraction = max(
                0.0,
                min(
                    1.0,
                    (sample - segment_start).dot(axis)
                    / max(0.000001, axis.length_squared),
                ),
            )
            shortest = min(shortest, (sample - (segment_start + axis * fraction)).length)
        return shortest <= radius

    def vertex_for(
        x_index: int,
        y_index: int,
        *,
        tail_region: bool,
    ) -> int:
        key = (tail_region, x_index, y_index)
        existing = vertex_map.get(key)
        if existing is not None:
            return existing
        u = x_index / columns
        v = y_index / rows
        visible_x = (u - 0.5) * CANVAS_WORLD_WIDTH
        world_x = visible_x if view == "front" else -visible_x
        world_z = CANVAS_WORLD_BOTTOM + v * CANVAS_WORLD_HEIGHT
        color = _pixel_sample(pixels, u, v)
        weights = _bone_weights(
            Vector((world_x, 0.0, world_z)),
            rig,
            color,
            force_tail=tail_region,
        )
        primary_bone = max(weights, key=weights.get)
        radial = 1 - min(1.0, abs(world_x) / (CANVAS_WORLD_WIDTH * 0.48))
        depth = 0.24 + radial * 0.16
        if tail_region or primary_bone.startswith("tail_"):
            depth = 0.56
        world_y = -depth if view == "front" else depth
        index = len(vertices)
        vertices.append((world_x, world_y, world_z))
        uv_values.append((u, v))
        vertex_weights.append(weights)
        vertex_map[key] = index
        return index

    for row in range(rows):
        v = (row + 0.5) / rows
        for column in range(columns):
            u = (column + 0.5) / columns
            world_z = CANVAS_WORLD_BOTTOM + v * CANVAS_WORLD_HEIGHT
            if minimum_z is not None and world_z < minimum_z:
                continue
            if minimum_z is not None and world_z < 5.82:
                neck_progress = _smoothstep(minimum_z, 5.82, world_z)
                neck_half_width = 0.26 + neck_progress * 0.36
                visible_x = (u - 0.5) * CANVAS_WORLD_WIDTH
                if abs(visible_x) > neck_half_width:
                    continue
            samples = (
                _pixel_sample(pixels, u, v),
                _pixel_sample(pixels, column / columns, row / rows),
                _pixel_sample(pixels, (column + 1) / columns, row / rows),
                _pixel_sample(pixels, column / columns, (row + 1) / rows),
                _pixel_sample(pixels, (column + 1) / columns, (row + 1) / rows),
            )
            sample = max(samples, key=lambda value: value[3])
            if sample[3] < 0.035:
                continue
            visible_x = (u - 0.5) * CANVAS_WORLD_WIDTH
            world_x = visible_x if view == "front" else -visible_x
            world_z = CANVAS_WORLD_BOTTOM + v * CANVAS_WORLD_HEIGHT
            # Keep the approved raster as one continuous skin during physique
            # sculpting. A split at the visible tail/body overlap creates seams
            # when the leg grows, even when both parts are individually valid.
            tail_region = False
            corners = (
                vertex_for(column, row, tail_region=tail_region),
                vertex_for(column + 1, row, tail_region=tail_region),
                vertex_for(column + 1, row + 1, tail_region=tail_region),
                vertex_for(column, row + 1, tail_region=tail_region),
            )
            faces.append(corners)

    data = bpy.data.meshes.new(f"{name}_MESH")
    data.from_pydata(vertices, [], faces)
    data.update()
    uv_layer = data.uv_layers.new(
        name="GymRatFrontUV" if view == "front" else "GymRatBackUV"
    )
    for polygon in data.polygons:
        for loop_index in polygon.loop_indices:
            vertex_index = data.loops[loop_index].vertex_index
            uv_layer.data[loop_index].uv = uv_values[vertex_index]
    shell = bpy.data.objects.new(name, data)
    model.objects.link(shell)
    shell.data.materials.append(
        _shell_material(
            f"MAT_{name}",
            image,
            "GymRatFrontUV" if view == "front" else "GymRatBackUV",
        )
    )
    groups = {
        bone: shell.vertex_groups.new(name=bone)
        for bone in sorted(
            {bone for weights in vertex_weights for bone in weights}
        )
    }
    group_counts = {bone: 0 for bone in groups}
    for index, weights in enumerate(vertex_weights):
        for bone, weight in weights.items():
            groups[bone].add((index,), weight, "REPLACE")
            group_counts[bone] += 1
    bpy.context.view_layer.update()
    print(name, group_counts)
    modifier = shell.modifiers.new(name="GymRat Armature", type="ARMATURE")
    modifier.object = rig
    modifier.use_deform_preserve_volume = True
    shell["gymrat_view"] = view
    return shell


def _add_ears(
    model: bpy.types.Collection,
    rig: bpy.types.Object,
    front_image: bpy.types.Image,
    back_image: bpy.types.Image,
    fallback: tuple[float, float, float, float],
) -> None:
    for side, sign in (("L", 1.0), ("R", -1.0)):
        bpy.ops.mesh.primitive_uv_sphere_add(
            segments=32,
            ring_count=20,
            location=(1.02 * sign, 0.02, 6.82),
            scale=(0.52, 0.16, 0.62),
        )
        ear = bpy.context.object
        ear.name = f"BODY_EAR_{side}"
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        _move_to_collection(ear, model)
        _project_uv(ear)
        _assign_master_materials(ear, front_image, back_image, fallback)
        group = ear.vertex_groups.new(name="head")
        group.add(range(len(ear.data.vertices)), 1.0, "REPLACE")
        modifier = ear.modifiers.new(name="GymRat Armature", type="ARMATURE")
        modifier.object = rig
        for polygon in ear.data.polygons:
            polygon.use_smooth = True


def _add_fist_coverage(
    model: bpy.types.Collection,
    rig: bpy.types.Object,
    front_image: bpy.types.Image,
    back_image: bpy.types.Image,
    fallback: tuple[float, float, float, float],
) -> None:
    for side in ("L", "R"):
        bone = rig.data.bones[f"hand.{side}"]
        location = Vector(bone.tail_local) * 0.80 + Vector(bone.head_local) * 0.20
        bpy.ops.mesh.primitive_uv_sphere_add(
            segments=24,
            ring_count=16,
            location=location,
            scale=(0.30, 0.22, 0.34),
        )
        fist = bpy.context.object
        fist.name = f"BODY_FIST_{side}"
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        _move_to_collection(fist, model)
        _project_uv(fist)
        _assign_master_materials(fist, front_image, back_image, fallback)
        group = fist.vertex_groups.new(name=f"hand.{side}")
        group.add(range(len(fist.data.vertices)), 1.0, "REPLACE")
        modifier = fist.modifiers.new(name="GymRat Armature", type="ARMATURE")
        modifier.object = rig
        for polygon in fist.data.polygons:
            polygon.use_smooth = True


def _add_tail_bones(rig: bpy.types.Object, contract: dict[str, object]) -> None:
    bpy.context.view_layer.objects.active = rig
    rig.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    armature = rig.data.edit_bones
    for name in ("tail_root", *(f"tail_{index:02d}" for index in range(1, 11))):
        existing = armature.get(name)
        if existing is not None:
            armature.remove(existing)
    pelvis = armature.get(str(contract["parent"]))
    if pelvis is None:
        raise RuntimeError("Converted donor has no pelvis bone")
    root = armature.new("tail_root")
    root.head = tuple(contract["head"])
    root.tail = tuple(contract["tail"])
    root.parent = pelvis
    path = (
        (0.25, 0.48, 2.95),
        (0.62, 0.52, 2.76),
        (0.98, 0.55, 2.48),
        (1.28, 0.57, 2.14),
        (1.40, 0.59, 1.80),
        (1.26, 0.60, 1.52),
        (0.95, 0.61, 1.37),
        (0.61, 0.62, 1.40),
        (0.36, 0.63, 1.58),
        (0.25, 0.64, 1.80),
    )
    parent = root
    start = Vector(root.tail)
    for index, coordinates in enumerate(path, start=1):
        end = Vector(coordinates)
        bone = armature.new(f"tail_{index:02d}")
        bone.head = start
        bone.tail = end
        bone.parent = parent
        parent = bone
        start = end
    bpy.ops.object.mode_set(mode="OBJECT")
    rig["gymrat_tail_anchor_contract"] = json.dumps(contract)


def _add_tail_mesh(
    model: bpy.types.Collection,
    rig: bpy.types.Object,
    front_image: bpy.types.Image,
    back_image: bpy.types.Image,
    fallback: tuple[float, float, float, float],
) -> None:
    bones = [rig.data.bones[f"tail_{index:02d}"] for index in range(1, 11)]
    points = [Vector(bones[0].head_local), *(Vector(bone.tail_local) for bone in bones)]
    sides = 12
    vertices: list[tuple[float, float, float]] = []
    for ring, point in enumerate(points):
        radius = 0.145 * (1 - ring / (len(points) + 1)) + 0.025
        for side in range(sides):
            angle = side / sides * math.tau
            vertices.append(
                (
                    point.x,
                    point.y + math.cos(angle) * radius,
                    point.z + math.sin(angle) * radius,
                )
            )
    faces: list[tuple[int, int, int, int]] = []
    for ring in range(len(points) - 1):
        for side in range(sides):
            next_side = (side + 1) % sides
            faces.append(
                (
                    ring * sides + side,
                    ring * sides + next_side,
                    (ring + 1) * sides + next_side,
                    (ring + 1) * sides + side,
                )
            )
    data = bpy.data.meshes.new("BODY_TAIL_MESH")
    data.from_pydata(vertices, [], faces)
    data.update()
    tail = bpy.data.objects.new("BODY_TAIL", data)
    model.objects.link(tail)
    _project_uv(tail)
    _assign_master_materials(tail, front_image, back_image, fallback)
    for polygon in tail.data.polygons:
        polygon.use_smooth = True
    for ring in range(len(points)):
        bone_index = max(1, min(10, ring))
        group = tail.vertex_groups.get(f"tail_{bone_index:02d}") or tail.vertex_groups.new(
            name=f"tail_{bone_index:02d}"
        )
        group.add(range(ring * sides, (ring + 1) * sides), 1.0, "REPLACE")
    modifier = tail.modifiers.new(name="GymRat Armature", type="ARMATURE")
    modifier.object = rig


def _smoothstep(edge0: float, edge1: float, value: float) -> float:
    t = max(0.0, min(1.0, (value - edge0) / max(0.0001, edge1 - edge0)))
    return t * t * (3 - 2 * t)


def _bell(value: float, start: float, peak: float, end: float) -> float:
    if value <= peak:
        return _smoothstep(start, peak, value)
    return 1 - _smoothstep(peak, end, value)


def _shape_keys(mesh: bpy.types.Object, rig: bpy.types.Object, stages: list[int]) -> None:
    if mesh.data.shape_keys is not None:
        bpy.context.view_layer.objects.active = mesh
        while mesh.data.shape_keys is not None:
            mesh.shape_key_remove(mesh.data.shape_keys.key_blocks[-1])
    basis = mesh.shape_key_add(name="Basis")
    base_coordinates = [point.co.copy() for point in basis.data]
    group_indices = {group.index: group.name for group in mesh.vertex_groups}
    affected_vertices = 0

    for level in stages:
        key = mesh.shape_key_add(name=f"PHYSIQUE_{level:03d}")
        level_progress = (level - stages[0]) / max(1, stages[-1] - stages[0])
        eased = level_progress**0.72
        for vertex_index, point in enumerate(key.data):
            coordinate = base_coordinates[vertex_index].copy()
            vertex = mesh.data.vertices[vertex_index]
            memberships = {
                group_indices.get(membership.group, ""): membership.weight
                for membership in vertex.groups
            }
            tail_weight = sum(
                weight
                for name, weight in memberships.items()
                if name.startswith("tail_")
            )
            face_weight = sum(
                memberships.get(name, 0.0)
                for name in ("head", "eyelid.L", "eyelid.R")
            )
            if tail_weight < 0.45 and face_weight < 0.65:
                outer = _smoothstep(0.38, 1.25, abs(coordinate.x))
                lats = _bell(coordinate.z, 3.72, 4.82, 5.72)
                delts = _bell(coordinate.z, 4.62, 5.32, 5.88) * outer
                arms = _bell(coordinate.z, 3.02, 4.30, 5.54) * outer
                thighs = _bell(coordinate.z, 1.35, 2.45, 3.38)
                calves = _bell(coordinate.z, 0.22, 1.10, 2.05)
                waist = _bell(coordinate.z, 3.18, 3.78, 4.22)
                gain_x = eased * (
                    lats * (0.30 + outer * 0.22)
                    + delts * 0.24
                    + arms * 0.38
                    + thighs * 0.65
                    + calves * 0.50
                    + waist * 0.14
                )
                gain_y = eased * (
                    lats * 0.72
                    + delts * 0.80
                    + arms * 0.66
                    + thighs * 0.55
                    + calves * 0.42
                )
                coordinate.x *= 1 + gain_x
                coordinate.y *= 1 + gain_y
                if level == stages[-1]:
                    affected_vertices += 1
            point.co = coordinate
        key.value = 1.0 if level == stages[0] else 0.0
    mesh["gymrat_physique_driver"] = True
    print(f"{mesh.name}: {affected_vertices} physique vertices")


def _shape_keys_donor(
    mesh: bpy.types.Object,
    rig: bpy.types.Object,
    stages: list[int],
    identity: str,
) -> None:
    """Author lean, local muscle growth instead of ballooning bone volumes.

    The previous pilot scaled every vertex radially around its nearest bone.
    That widened joints, waists and entire limb cylinders together, which read
    as a padded suit. These shape keys preserve attachment points and add
    tapered muscle bellies: deltoid/biceps/triceps, forearm, quadriceps/
    hamstring, calf, pectoral, lat, trap and abdominal regions.
    """
    basis = mesh.shape_key_add(name="Basis")
    base_coordinates = [point.co.copy() for point in basis.data]
    group_names = {group.index: group.name for group in mesh.vertex_groups}
    relevant_bones = {
        "spine_02",
        "chest",
        "upper_arm.L",
        "upper_arm.R",
        "forearm.L",
        "forearm.R",
        "thigh.L",
        "thigh.R",
        "shin.L",
        "shin.R",
    }
    identity_gain = {
        "male": 1.00,
        "female": 0.86,
        "non_binary": 0.92,
    }[identity]
    # The donor starts athletic. Negative values slim only the muscle bellies
    # for level 1; wrists, elbows, knees, ankles, hands and feet remain fixed.
    start_strength = {
        "male": -0.20,
        "female": -0.30,
        "non_binary": -0.26,
    }[identity]

    def bone_sample(
        coordinate: Vector, bone_name: str
    ) -> tuple[Vector, Vector, float, Vector, float]:
        bone = rig.data.bones[bone_name]
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
        center = head + axis * fraction
        radial = coordinate - center
        return head, axis, fraction, radial, radial.length

    def add_radial_belly(
        coordinate: Vector,
        bone_name: str,
        strength: float,
        amplitude: float,
        start: float,
        peak: float,
        end: float,
        weight: float,
        *,
        front_bias: float = 0.0,
        side_bias: float = 0.0,
    ) -> Vector:
        _, _, fraction, radial, radius = bone_sample(coordinate, bone_name)
        if radius < 0.0001:
            return coordinate
        taper = _bell(fraction, start, peak, end)
        if taper <= 0:
            return coordinate
        direction = radial / radius
        # Front of the character is negative Y in the authored scene.
        frontness = max(-1.0, min(1.0, -direction.y))
        sideness = abs(direction.x)
        lobe = max(
            0.35,
            1.0 + front_bias * frontness + side_bias * (sideness - 0.45),
        )
        return coordinate + direction * amplitude * taper * lobe * strength * weight

    for level in stages:
        key = mesh.shape_key_add(name=f"PHYSIQUE_{level:03d}")
        progress = STAGE_PROGRESS.get(level)
        if progress is None:
            progress = stages.index(level) / max(1, len(stages) - 1)
        # Early changes stay restrained; late changes accelerate into the
        # intentionally extreme final silhouette.
        growth = progress**0.88
        strength = start_strength * (1.0 - growth) + identity_gain * growth
        for vertex_index, point in enumerate(key.data):
            coordinate = base_coordinates[vertex_index].copy()
            memberships = {
                group_names.get(membership.group, ""): membership.weight
                for membership in mesh.data.vertices[vertex_index].groups
                if group_names.get(membership.group, "") in relevant_bones
            }

            for bone_name, weight in memberships.items():
                if weight < 0.025:
                    continue
                if bone_name.startswith("upper_arm"):
                    # Rounded deltoid cap, then distinct biceps/triceps belly;
                    # both vanish before the elbow so it stays articulated.
                    coordinate = add_radial_belly(
                        coordinate,
                        bone_name,
                        strength,
                        0.34,
                        0.00,
                        0.14,
                        0.36,
                        weight,
                        side_bias=0.38,
                    )
                    coordinate = add_radial_belly(
                        coordinate,
                        bone_name,
                        strength,
                        0.29,
                        0.18,
                        0.52,
                        0.90,
                        weight,
                        front_bias=0.22,
                    )
                elif bone_name.startswith("forearm"):
                    coordinate = add_radial_belly(
                        coordinate,
                        bone_name,
                        strength,
                        0.22,
                        0.04,
                        0.34,
                        0.86,
                        weight,
                        front_bias=-0.08,
                        side_bias=0.18,
                    )
                elif bone_name.startswith("thigh"):
                    # Quads are strongest on the front/outer surface;
                    # hamstrings add a smaller rear belly. Knee remains narrow.
                    coordinate = add_radial_belly(
                        coordinate,
                        bone_name,
                        strength,
                        0.39,
                        0.04,
                        0.42,
                        0.91,
                        weight,
                        front_bias=0.20,
                        side_bias=0.28,
                    )
                elif bone_name.startswith("shin"):
                    # Gastrocnemius peaks high and tapers decisively to ankle.
                    coordinate = add_radial_belly(
                        coordinate,
                        bone_name,
                        strength,
                        0.30,
                        0.04,
                        0.31,
                        0.76,
                        weight,
                        front_bias=-0.18,
                        side_bias=0.20,
                    )

            torso_weight = max(
                memberships.get("chest", 0.0),
                memberships.get("spine_02", 0.0),
            )
            if torso_weight > 0.025:
                x = coordinate.x
                y = coordinate.y
                z = coordinate.z
                side = 1.0 if x >= 0 else -1.0
                front_surface = _smoothstep(0.02, 0.34, -y)
                rear_surface = _smoothstep(0.02, 0.34, y)

                # Lats widen the upper back while keeping the waist tight.
                lat = _bell(z, 3.92, 4.73, 5.48) * _smoothstep(0.34, 1.02, abs(x))
                coordinate.x += side * 0.36 * lat * strength * torso_weight
                coordinate.y += 0.11 * lat * rear_surface * strength * torso_weight

                # Two pectoral bellies project forward; the center sternum and
                # lower ribcage stay defined instead of becoming a barrel.
                pec_height = _bell(z, 4.58, 5.02, 5.48)
                pec_side = _bell(abs(x), 0.10, 0.52, 1.18)
                coordinate.y -= (
                    0.34
                    * pec_height
                    * pec_side
                    * front_surface
                    * strength
                    * torso_weight
                )

                # Traps rise from the inner shoulders without altering neck or
                # head scale.
                trap = _bell(z, 5.05, 5.42, 5.72) * (
                    1.0 - _smoothstep(0.30, 1.12, abs(x))
                )
                coordinate.y += 0.15 * trap * rear_surface * strength * torso_weight
                coordinate.x += side * 0.08 * trap * strength * torso_weight

                # Abdominal development is shallow relief, not waist growth.
                abs_region = _bell(z, 3.45, 4.04, 4.65)
                abs_center = 1.0 - _smoothstep(0.18, 0.62, abs(x))
                row_phase = math.cos((z - 3.48) * math.pi * 5.0)
                coordinate.y -= (
                    0.045
                    * abs_region
                    * abs_center
                    * front_surface
                    * max(0.0, row_phase)
                    * max(0.0, strength)
                    * torso_weight
                )
            point.co = coordinate
        key.value = 1.0 if level == stages[0] else 0.0
    mesh["gymrat_physique_driver"] = True


def _set_stage(mesh: bpy.types.Object, stages: list[int], stage: int) -> None:
    selected = max((level for level in stages if level <= stage), default=stages[0])
    for level in stages:
        mesh.data.shape_keys.key_blocks[f"PHYSIQUE_{level:03d}"].value = (
            1.0 if level == selected else 0.0
        )


def _preview(path: Path, view: str) -> None:
    scene = bpy.context.scene
    scene.camera = bpy.data.objects["CAM_FRONT" if view == "front" else "CAM_BACK"]
    for obj in bpy.data.collections["MODEL_AUTHORED"].objects:
        authored_view = obj.get("gymrat_view")
        obj.hide_render = authored_view is not None and authored_view != view
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_percentage = 50
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.film_transparent = True
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.render.filepath = str(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    lights = bpy.data.collections.get("LIGHTS")
    if lights is None:
        lights = bpy.data.collections.new("LIGHTS")
        scene.collection.children.link(lights)
    for obj in tuple(lights.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for name, location, energy, size in (
        ("KEY", (-4.0, -5.0, 8.5), 950.0, 4.0),
        ("RIM", (4.2, 1.5, 7.2), 720.0, 3.0),
        ("FILL", (0.0, -3.0, 3.0), 420.0, 3.5),
    ):
        data = bpy.data.lights.new(name, type="AREA")
        data.energy = energy
        data.shape = "DISK"
        data.size = size
        obj = bpy.data.objects.new(name, data)
        obj.location = location
        direction = Vector((0, 0, 4.0)) - obj.location
        obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
        lights.objects.link(obj)
    bpy.ops.render.render(write_still=True)


def main() -> None:
    args = _arguments()
    repo_root = args.repo_root.resolve()
    source_root = args.source_root.resolve()
    manifest = json.loads(
        (repo_root / "tool/character_pipeline/pipeline_manifest.json").read_text(
            encoding="utf-8"
        )
    )
    sources = json.loads(
        (repo_root / "tool/character_pipeline/topology_sources.json").read_text(
            encoding="utf-8"
        )
    )
    donor_contract = sources["mast_cc0"]
    donor_path = source_root / donor_contract["external_path"]
    if not donor_path.is_file() or _sha256(donor_path) != donor_contract["sha256"]:
        raise RuntimeError("CC0 topology donor is missing or its checksum drifted")

    scene_path = source_root / "scenes" / f"{args.identity}_character.blend"
    bpy.ops.wm.open_mainfile(filepath=str(scene_path))
    model = bpy.data.collections.get("MODEL_AUTHORED")
    rig_collection = bpy.data.collections.get("RIG")
    if model is None or rig_collection is None:
        raise RuntimeError("GymRat scene collections are missing")
    _clear_collection(model)
    _clear_collection(rig_collection)

    mesh, rig = _load_donor(donor_path)
    _prepare_donor(mesh, rig, model, rig_collection)
    _rename_contract_bones(mesh, rig)
    if args.geometry != "procedural":
        profile = _master_profile(bpy.data.objects["REF_FRONT"].data)
        _fit_mesh_to_master(mesh, profile)
        _reshape_contract_rig(rig, mesh)
    else:
        for modifier in mesh.modifiers:
            if modifier.type == "SUBSURF":
                modifier.levels = 2
                modifier.render_levels = 2

    front_image = bpy.data.objects["REF_FRONT"].data
    back_image = bpy.data.objects["REF_BACK"].data
    tail_contract = manifest["anatomy_contract"]["tail_anchor"]
    _add_tail_bones(rig, tail_contract)
    print(
        "Contract bones:",
        {
            name: (
                tuple(round(float(value), 2) for value in rig.data.bones[name].head_local),
                tuple(round(float(value), 2) for value in rig.data.bones[name].tail_local),
            )
            for name in ("chest", "upper_arm.L", "forearm.L", "thigh.L", "shin.L")
        },
    )
    if args.geometry == "shell":
        front_shell = _build_master_shell(
            "BODY_GYMRAT_FRONT",
            front_image,
            rig,
            model,
            view="front",
        )
        back_shell = _build_master_shell(
            "BODY_GYMRAT_BACK",
            back_image,
            rig,
            model,
            view="back",
        )
        bpy.data.objects.remove(mesh, do_unlink=True)
        authored_meshes = (front_shell, back_shell)
    elif args.geometry == "donor":
        mesh.name = "BODY_GYMRAT"
        _project_uv(mesh)
        _assign_master_materials(
            mesh,
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
        authored_meshes = (mesh,)
    else:
        mesh.name = "BODY_GYMRAT"
        _style_procedural_character(mesh, rig, model, args.identity)
        _build_master_shell(
            "HEAD_GYMRAT_FRONT",
            front_image,
            rig,
            model,
            view="front",
            minimum_z=5.58,
        )
        _build_master_shell(
            "HEAD_GYMRAT_BACK",
            back_image,
            rig,
            model,
            view="back",
            minimum_z=5.58,
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
            _physical_material(
                "MAT_TAIL", (0.48, 0.16, 0.13, 1.0), roughness=0.58
            )
        )
        authored_meshes = (mesh,)
    for authored_mesh in authored_meshes:
        if args.geometry == "shell":
            _shape_keys(authored_mesh, rig, manifest["stages"])
        else:
            _shape_keys_donor(
                authored_mesh,
                rig,
                manifest["stages"],
                args.identity,
            )
        _set_stage(authored_mesh, manifest["stages"], args.stage)
    print(
        "Authored vertices:",
        sum(len(authored_mesh.data.vertices) for authored_mesh in authored_meshes),
    )
    rig["gymrat_rig_contract"] = 2
    model["gymrat_model_status"] = "cc0_topology_identity_pilot"
    model["gymrat_topology_source"] = donor_contract["source"]
    model["gymrat_topology_license"] = donor_contract["license"]
    bpy.context.scene["gymrat_model_review_required"] = True
    if args.motion is not None:
        sys.path.insert(0, str(repo_root / "tool/character_pipeline"))
        from author_motion_library import _author_emote, _author_simple

        action_name = (
            f"ACT_{args.view}_{args.motion}"
            if args.motion in {"double_biceps", "chest_flex", "leg_pose", "triceps"}
            else f"ACT_{args.motion}"
        )
        if args.motion in {"double_biceps", "chest_flex", "leg_pose", "triceps"}:
            _author_emote(
                rig,
                args.motion,
                args.view,
                manifest["motions"][args.motion],
                manifest["emote_contract"]["pose_specs"][args.motion],
            )
        else:
            _author_simple(rig, args.motion, manifest["motions"][args.motion])
        action = bpy.data.actions.get(action_name)
        if action is None:
            raise RuntimeError(f"Motion action is missing: {action_name}")
        rig.animation_data_create()
        rig.animation_data.action = action
    bpy.context.scene.frame_set(args.frame)

    if args.render_preview is not None:
        _preview(args.render_preview.resolve(), args.view)
    if args.dry_run:
        print(f"Built {args.identity} CC0 topology pilot without saving")
        return
    bpy.ops.wm.save_as_mainfile(filepath=str(scene_path))
    print(f"Built {args.identity} CC0 topology pilot in {scene_path}")


if __name__ == "__main__":
    try:
        main()
    except Exception:
        traceback.print_exc()
        raise SystemExit(1)
