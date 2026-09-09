#!/usr/bin/env python3
"""Export approved GymRat Blender sources as animated runtime GLB files.

The exporter has no bypass for incomplete scenes. A character must pass the
same render-ready gate used before sprite rendering, including a rig-bound
mesh, reviewed model state, authored actions, and every physique milestone.
"""

from __future__ import annotations

import argparse
import json
import sys
import traceback
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
from validate_blender_scenes import _validate_scene


def _arguments() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, required=True)
    parser.add_argument("--source-root", type=Path, required=True)
    parser.add_argument("--export-root", type=Path)
    parser.add_argument(
        "--identity",
        action="append",
        choices=("male", "female", "non_binary"),
    )
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args(argv)


def _collection_objects(
    collection: bpy.types.Collection,
) -> set[bpy.types.Object]:
    objects = set(collection.objects)
    for child in collection.children:
        objects.update(_collection_objects(child))
    return objects


def _export_scene(scene_path: Path, output_path: Path) -> None:
    bpy.ops.wm.open_mainfile(filepath=str(scene_path))
    model = bpy.data.collections.get("MODEL_AUTHORED")
    rig = bpy.data.objects.get("RIG_GYMRAT")
    if model is None or rig is None:
        raise RuntimeError(f"Render-ready objects disappeared from {scene_path}")

    bpy.ops.object.select_all(action="DESELECT")
    exported = _collection_objects(model)
    exported.add(rig)
    for obj in exported:
        obj.hide_render = False
        obj.hide_set(False)
        obj.select_set(True)
    bpy.context.view_layer.objects.active = rig

    output_path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(output_path),
        export_format="GLB",
        use_selection=True,
        export_cameras=False,
        export_lights=False,
        export_extras=True,
        export_skins=True,
        export_all_influences=True,
        export_morph=True,
        export_morph_animation=True,
        export_morph_normal=True,
        export_animations=True,
        export_animation_mode="ACTIONS",
        export_force_sampling=True,
        export_frame_range=False,
        export_optimize_animation_size=True,
        export_yup=True,
        check_existing=False,
    )


def main() -> int:
    args = _arguments()
    repo_root = args.repo_root.resolve()
    source_root = args.source_root.resolve()
    export_root = (args.export_root or source_root / "runtime_exports").resolve()
    manifest = json.loads(
        (repo_root / "tool/character_pipeline/pipeline_manifest.json").read_text(
            encoding="utf-8"
        )
    )
    identities = args.identity or list(manifest["identities"])

    scene_paths: dict[str, Path] = {}
    errors: list[str] = []
    for identity in identities:
        scene_path = source_root / "scenes" / f"{identity}_character.blend"
        scene_paths[identity] = scene_path
        errors.extend(
            _validate_scene(
                scene_path,
                identity,
                manifest,
                require_render_ready=True,
            )
        )

    if errors:
        print("Runtime GLB export blocked:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    if args.dry_run:
        print(f"Validated {len(identities)} runtime GLB export source(s).")
        return 0

    for identity, scene_path in scene_paths.items():
        output_path = export_root / f"gymrat_{identity}.glb"
        _export_scene(scene_path, output_path)
        print(f"Exported {output_path}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except SystemExit:
        raise
    except Exception:
        traceback.print_exc()
        raise SystemExit(1)
