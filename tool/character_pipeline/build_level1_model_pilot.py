#!/usr/bin/env python3
"""Build a rig-bound level-1 GymRat model pilot from approved proportions.

This is a deterministic Blender authoring tool, not an AI image generator. It
creates editable body, clothing, face, and tail meshes in MODEL_AUTHORED while
leaving the approved front/back masters locked as references. Runtime exports
remain blocked until a human review accepts the rendered identity match.
"""

from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


IDENTITIES = ("male", "female", "non_binary")
CANVAS_WORLD_HEIGHT = 7.25
CANVAS_WORLD_WIDTH = CANVAS_WORLD_HEIGHT * 1024 / 1792
CANVAS_WORLD_BOTTOM = 3.7 - CANVAS_WORLD_HEIGHT / 2


def _arguments() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-root", type=Path, required=True)
    parser.add_argument("--identity", choices=IDENTITIES, required=True)
    parser.add_argument("--render-preview", type=Path)
    parser.add_argument("--motion")
    parser.add_argument("--view", choices=("front", "back"), default="front")
    parser.add_argument("--frame", type=int, default=1)
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args(argv)


def _material(
    name: str,
    color: tuple[float, float, float, float],
    *,
    roughness: float = 0.6,
    metallic: float = 0.0,
    noise_bump: bool = False,
) -> bpy.types.Material:
    material = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    material.diffuse_color = color
    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    nodes.clear()
    output = nodes.new("ShaderNodeOutputMaterial")
    shader = nodes.new("ShaderNodeBsdfPrincipled")
    shader.inputs["Base Color"].default_value = color
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Metallic"].default_value = metallic
    links.new(shader.outputs["BSDF"], output.inputs["Surface"])
    if noise_bump:
        noise = nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = 38.0
        noise.inputs["Detail"].default_value = 7.0
        noise.inputs["Roughness"].default_value = 0.72
        bump = nodes.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = 0.16
        bump.inputs["Distance"].default_value = 0.035
        links.new(noise.outputs["Fac"], bump.inputs["Height"])
        links.new(bump.outputs["Normal"], shader.inputs["Normal"])
    return material


def _master_material(
    name: str, fallback: tuple[float, float, float, float]
) -> bpy.types.Material:
    front_reference = bpy.data.objects.get("REF_FRONT")
    back_reference = bpy.data.objects.get("REF_BACK")
    if front_reference is None or back_reference is None:
        raise RuntimeError("Approved front/back references are missing")
    material = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    nodes.clear()
    output = nodes.new("ShaderNodeOutputMaterial")
    shader = nodes.new("ShaderNodeBsdfPrincipled")
    shader.inputs["Roughness"].default_value = 0.74
    front_uv = nodes.new("ShaderNodeUVMap")
    front_uv.uv_map = "GymRatFrontUV"
    back_uv = nodes.new("ShaderNodeUVMap")
    back_uv.uv_map = "GymRatBackUV"
    front = nodes.new("ShaderNodeTexImage")
    front.image = front_reference.data
    front.interpolation = "Linear"
    back = nodes.new("ShaderNodeTexImage")
    back.image = back_reference.data
    back.interpolation = "Linear"
    geometry = nodes.new("ShaderNodeNewGeometry")
    front_surface = nodes.new("ShaderNodeMixRGB")
    back_surface = nodes.new("ShaderNodeMixRGB")
    view_mix = nodes.new("ShaderNodeMixRGB")
    front_surface.inputs[1].default_value = fallback
    back_surface.inputs[1].default_value = fallback
    links.new(front_uv.outputs["UV"], front.inputs["Vector"])
    links.new(back_uv.outputs["UV"], back.inputs["Vector"])
    links.new(front.outputs["Alpha"], front_surface.inputs[0])
    links.new(front.outputs["Color"], front_surface.inputs[2])
    links.new(back.outputs["Alpha"], back_surface.inputs[0])
    links.new(back.outputs["Color"], back_surface.inputs[2])
    links.new(geometry.outputs["Backfacing"], view_mix.inputs[0])
    links.new(front_surface.outputs["Color"], view_mix.inputs[1])
    links.new(back_surface.outputs["Color"], view_mix.inputs[2])
    links.new(view_mix.outputs["Color"], shader.inputs["Base Color"])
    links.new(shader.outputs["BSDF"], output.inputs["Surface"])
    return material


def _project_master_uv(obj: bpy.types.Object) -> None:
    for layer_name in ("GymRatFrontUV", "GymRatBackUV"):
        previous = obj.data.uv_layers.get(layer_name)
        if previous is not None:
            obj.data.uv_layers.remove(previous)
    front = obj.data.uv_layers.new(name="GymRatFrontUV")
    back = obj.data.uv_layers.new(name="GymRatBackUV")
    for polygon in obj.data.polygons:
        for loop_index in polygon.loop_indices:
            vertex = obj.data.vertices[obj.data.loops[loop_index].vertex_index]
            world = obj.matrix_world @ vertex.co
            u = (world.x + CANVAS_WORLD_WIDTH / 2) / CANVAS_WORLD_WIDTH
            v = (world.z - CANVAS_WORLD_BOTTOM) / CANVAS_WORLD_HEIGHT
            front.data[loop_index].uv = (u, v)
            back.data[loop_index].uv = (1.0 - u, v)


def _move_to_collection(
    obj: bpy.types.Object, collection: bpy.types.Collection
) -> None:
    for owner in tuple(obj.users_collection):
        owner.objects.unlink(obj)
    collection.objects.link(obj)


def _bind(
    obj: bpy.types.Object, rig: bpy.types.Object, bone_name: str
) -> bpy.types.Object:
    group = obj.vertex_groups.new(name=bone_name)
    group.add(range(len(obj.data.vertices)), 1.0, "REPLACE")
    modifier = obj.modifiers.new(name="GymRat Armature", type="ARMATURE")
    modifier.object = rig
    modifier.use_deform_preserve_volume = True
    obj["gymrat_bound_bone"] = bone_name
    obj["gymrat_level"] = 1
    return obj


def _sphere(
    name: str,
    location: tuple[float, float, float],
    scale: tuple[float, float, float],
    material: bpy.types.Material,
    collection: bpy.types.Collection,
    rig: bpy.types.Object,
    bone: str,
    *,
    segments: int = 32,
    bind: bool = True,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=segments,
        ring_count=max(12, segments // 2),
        location=location,
    )
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    obj.data.materials.append(material)
    if material.name.startswith("MAT_MASTER_PROJECTED"):
        _project_master_uv(obj)
    _move_to_collection(obj, collection)
    return _bind(obj, rig, bone) if bind else obj


def _capsule_on_bone(
    name: str,
    rig: bpy.types.Object,
    bone_name: str,
    radius: float,
    depth_scale: float,
    material: bpy.types.Material,
    collection: bpy.types.Collection,
    *,
    inset: float = 0.08,
    bind: bool = True,
) -> bpy.types.Object:
    bone = rig.data.bones[bone_name]
    head = Vector(bone.head_local)
    tail = Vector(bone.tail_local)
    direction = tail - head
    length = max(0.05, direction.length - inset)
    center = (head + tail) * 0.5
    obj = _sphere(
        name,
        tuple(center),
        (radius, radius * depth_scale, length * 0.58),
        material,
        collection,
        rig,
        bone_name,
        segments=24,
        bind=bind,
    )
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = direction.to_track_quat("Z", "Y")
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    if material.name.startswith("MAT_MASTER_PROJECTED"):
        _project_master_uv(obj)
    return obj


def _join_and_skin_body(
    parts: list[bpy.types.Object],
    rig: bpy.types.Object,
    material: bpy.types.Material,
) -> bpy.types.Object:
    if not parts:
        raise RuntimeError("Body pilot has no mesh parts")
    bpy.ops.object.select_all(action="DESELECT")
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    body = bpy.context.object
    body.name = "BODY_SKIN"

    remesh = body.modifiers.new(name="Organic body union", type="REMESH")
    remesh.mode = "VOXEL"
    remesh.voxel_size = 0.055
    remesh.use_smooth_shade = True
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.modifier_apply(modifier=remesh.name)
    smooth = body.modifiers.new(name="Surface smoothing", type="SMOOTH")
    smooth.factor = 0.42
    smooth.iterations = 3
    bpy.ops.object.modifier_apply(modifier=smooth.name)

    body.data.materials.clear()
    body.data.materials.append(material)
    _project_master_uv(body)

    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")
    armature_modifiers = [
        modifier for modifier in body.modifiers if modifier.type == "ARMATURE"
    ]
    if not armature_modifiers:
        raise RuntimeError("Automatic body skinning did not create an armature modifier")
    armature_modifiers[0].use_deform_preserve_volume = True
    body["gymrat_level"] = 1
    body["gymrat_skinning"] = "automatic_heat"
    return body


def _curve_tail(
    rig: bpy.types.Object,
    collection: bpy.types.Collection,
    material: bpy.types.Material,
) -> None:
    for index in range(1, 11):
        bone_name = f"tail_{index:02d}"
        radius = 0.155 - index * 0.0095
        _capsule_on_bone(
            f"BODY_TAIL_{index:02d}",
            rig,
            bone_name,
            max(0.045, radius),
            1.0,
            material,
            collection,
            inset=-0.06,
        )


def _clear_model(collection: bpy.types.Collection) -> None:
    for obj in tuple(collection.objects):
        bpy.data.objects.remove(obj, do_unlink=True)


def _build(identity: str, rig: bpy.types.Object) -> None:
    model = bpy.data.collections.get("MODEL_AUTHORED")
    if model is None:
        raise RuntimeError("MODEL_AUTHORED collection is missing")
    _clear_model(model)

    fur_colors = {
        "male": (0.026, 0.013, 0.008, 1.0),
        "female": (0.042, 0.021, 0.013, 1.0),
        "non_binary": (0.034, 0.017, 0.011, 1.0),
    }
    proportions = {
        "male": {
            "chest": (1.18, 0.62, 0.82),
            "waist": (0.76, 0.45, 0.72),
            "hips": (0.76, 0.48, 0.52),
            "arm": 0.36,
            "leg": 0.43,
            "head": (0.76, 0.62, 0.72),
        },
        "female": {
            "chest": (0.83, 0.50, 0.67),
            "waist": (0.60, 0.39, 0.65),
            "hips": (0.82, 0.53, 0.58),
            "arm": 0.245,
            "leg": 0.37,
            "head": (0.67, 0.55, 0.67),
        },
        "non_binary": {
            "chest": (0.88, 0.52, 0.71),
            "waist": (0.64, 0.41, 0.67),
            "hips": (0.75, 0.50, 0.55),
            "arm": 0.275,
            "leg": 0.385,
            "head": (0.69, 0.57, 0.68),
        },
    }[identity]

    skin = _material("MAT_SKIN", (0.73, 0.28, 0.22, 1.0), roughness=0.48)
    accent = _material("MAT_ACCENT", (0.18, 0.82, 0.30, 1.0), roughness=0.42)
    master = _master_material("MAT_MASTER_PROJECTED_BODY", fur_colors[identity])
    master_cloth = _master_material(
        "MAT_MASTER_PROJECTED_CLOTH", (0.012, 0.015, 0.014, 1.0)
    )

    body_parts = [
        _sphere(
            "BODY_CHEST",
            (0, 0, 4.92),
            proportions["chest"],
            master,
            model,
            rig,
            "chest",
            bind=False,
        ),
        _sphere(
            "BODY_WAIST",
            (0, 0, 4.02),
            proportions["waist"],
            master,
            model,
            rig,
            "spine_02",
            bind=False,
        ),
        _sphere(
            "BODY_HIPS",
            (0, 0, 3.25),
            proportions["hips"],
            master,
            model,
            rig,
            "pelvis",
            bind=False,
        ),
        _sphere(
            "BODY_NECK",
            (0, -0.01, 5.72),
            (0.46, 0.43, 0.53),
            master,
            model,
            rig,
            "neck",
            bind=False,
        ),
        _sphere(
            "BODY_HEAD",
            (0, -0.02, 6.47),
            proportions["head"],
            master,
            model,
            rig,
            "head",
            bind=False,
        ),
        _sphere(
            "BODY_MUZZLE",
            (0, -0.50, 6.28),
            (0.43, 0.34, 0.28),
            master,
            model,
            rig,
            "head",
            segments=24,
            bind=False,
        ),
    ]

    for side, sign in (("L", 1.0), ("R", -1.0)):
        body_parts.append(
            _sphere(
                f"BODY_EAR_{side}",
                (0.49 * sign, 0.0, 6.93),
                (0.34, 0.16, 0.43),
                master,
                model,
                rig,
                f"ear.{side}",
                segments=24,
                bind=False,
            )
        )
        for part_name, bone_name, radius, depth, inset in (
            (
                "UPPER_ARM",
                f"upper_arm.{side}",
                proportions["arm"] * 1.08,
                0.86,
                0.08,
            ),
            ("FOREARM", f"forearm.{side}", proportions["arm"], 0.82, 0.08),
            (
                "HAND",
                f"hand.{side}",
                proportions["arm"] * 0.80,
                0.78,
                -0.04,
            ),
            (
                "THIGH",
                f"thigh.{side}",
                proportions["leg"] * 1.08,
                0.91,
                0.08,
            ),
            ("SHIN", f"shin.{side}", proportions["leg"] * 0.82, 0.88, 0.08),
            (
                "FOOT",
                f"foot.{side}",
                proportions["leg"] * 0.72,
                0.92,
                -0.10,
            ),
        ):
            body_parts.append(
                _capsule_on_bone(
                    f"BODY_{part_name}_{side}",
                    rig,
                    bone_name,
                    radius,
                    depth,
                    master,
                    model,
                    inset=inset,
                    bind=False,
                )
            )

        # Distal-bone joint shells keep silhouettes closed while the rigidly
        # weighted pilot bends. A production sculpt can later replace them
        # without changing the motion contract or bone names.
        for joint_name, bone_name, radius in (
            ("SHOULDER", f"upper_arm.{side}", proportions["arm"] * 1.02),
            ("ELBOW", f"forearm.{side}", proportions["arm"] * 0.84),
            ("WRIST", f"hand.{side}", proportions["arm"] * 0.66),
            ("KNEE", f"shin.{side}", proportions["leg"] * 0.78),
            ("ANKLE", f"foot.{side}", proportions["leg"] * 0.58),
        ):
            bone = rig.data.bones[bone_name]
            body_parts.append(
                _sphere(
                    f"BODY_{joint_name}_{side}",
                    tuple(bone.head_local),
                    (radius, radius * 0.88, radius),
                    master,
                    model,
                    rig,
                    bone_name,
                    segments=20,
                    bind=False,
                )
            )

        # Shorts are complete model geometry, not runtime overlays.
        _sphere(
            f"CLOTH_SHORTS_{side}",
            (0.42 * sign, -0.005, 3.12),
            (0.57, 0.54, 0.60),
            master_cloth,
            model,
            rig,
            "pelvis",
            segments=24,
        )

    _sphere("CLOTH_WAISTBAND", (0, 0, 3.56), (0.83, 0.53, 0.19), master_cloth, model, rig, "pelvis", segments=32)
    _sphere("CLOTH_ACCENT", (0.69, -0.42, 3.16), (0.08, 0.025, 0.19), accent, model, rig, "pelvis", segments=16)
    if identity == "female":
        _sphere("CLOTH_TRAINING_TOP", (0, -0.20, 4.94), (0.90, 0.47, 0.64), master_cloth, model, rig, "chest")
        _sphere("CLOTH_TOP_TRIM", (0, -0.59, 4.98), (0.68, 0.025, 0.08), accent, model, rig, "chest", segments=20)
    elif identity == "non_binary":
        _sphere("CLOTH_HIGH_TOP", (0, -0.18, 5.02), (0.92, 0.49, 0.78), master_cloth, model, rig, "chest")
        _sphere("CLOTH_TOP_ACCENT", (0.73, -0.49, 4.90), (0.045, 0.025, 0.44), accent, model, rig, "chest", segments=16)

    _join_and_skin_body(body_parts, rig, master)
    _curve_tail(rig, model, skin)
    model["gymrat_model_status"] = "level_1_proportion_pilot"
    model["gymrat_identity"] = identity
    bpy.context.scene["gymrat_model_review_required"] = True


def _configure_preview(
    path: Path,
    frame: int,
    *,
    rig: bpy.types.Object,
    motion: str | None,
    view: str,
) -> None:
    scene = bpy.context.scene
    camera_name = "CAM_FRONT" if view == "front" else "CAM_BACK"
    scene.camera = bpy.data.objects[camera_name]
    if motion is not None:
        action_name = f"ACT_{view}_{motion}"
        action = bpy.data.actions.get(action_name)
        if action is None:
            action = bpy.data.actions.get(f"ACT_{motion}")
        if action is None:
            raise RuntimeError(f"Preview action {action_name} is missing")
        rig.animation_data_create()
        rig.animation_data.action = action
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_percentage = 50
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.film_transparent = True
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.render.filepath = str(path)
    scene.frame_set(frame)
    lights = bpy.data.collections.get("LIGHTS")
    if lights is None:
        lights = bpy.data.collections.new("LIGHTS")
        scene.collection.children.link(lights)
    for obj in tuple(lights.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for name, location, energy, size in (
        ("KEY", (-4.0, -5.0, 8.5), 1150.0, 4.0),
        ("RIM", (4.2, 1.5, 7.2), 900.0, 3.0),
        ("FILL", (0.0, -3.0, 3.0), 500.0, 3.5),
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
    path.parent.mkdir(parents=True, exist_ok=True)


def main() -> None:
    args = _arguments()
    scene_path = args.source_root / "scenes" / f"{args.identity}_character.blend"
    if not scene_path.is_file():
        raise FileNotFoundError(scene_path)
    bpy.ops.wm.open_mainfile(filepath=str(scene_path))
    rig = bpy.data.objects.get("RIG_GYMRAT")
    if rig is None or rig.type != "ARMATURE":
        raise RuntimeError("RIG_GYMRAT armature is missing")
    bpy.context.scene.frame_set(1)
    _build(args.identity, rig)
    if args.render_preview is not None:
        _configure_preview(
            args.render_preview.resolve(),
            args.frame,
            rig=rig,
            motion=args.motion,
            view=args.view,
        )
        bpy.ops.render.render(write_still=True)
    if args.dry_run:
        print(f"Built {args.identity} level-1 model pilot without saving")
        return
    bpy.ops.wm.save_as_mainfile(filepath=str(scene_path))
    print(f"Built {args.identity} level-1 model pilot in {scene_path}")


if __name__ == "__main__":
    main()
