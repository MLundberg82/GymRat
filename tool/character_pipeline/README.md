# GymRat character source pipeline

This pipeline turns the six approved level-1 renders into three independently
authored Blender character lines. It does not bundle Blender source files or
draft renders in the Flutter application.

## Local source location

The bootstrap command creates source files in the sibling directory
`../GymRat-character-source`. That directory stays outside the repository so
large `.blend` files, draft renders, caches, and intermediate textures cannot
be committed or shipped accidentally.

## Bootstrap

```sh
/Users/mattias/Applications/Blender.app/Contents/MacOS/Blender \
  --background \
  --python-exit-code 1 \
  --python tool/character_pipeline/bootstrap_blender_scenes.py \
  -- \
  --repo-root "$PWD" \
  --source-root "$(dirname "$PWD")/GymRat-character-source"
```

The command creates one scene per identity with:

- immutable front/back reference links and SHA-256 fingerprints;
- stable front/back orthographic cameras;
- separate model, rig, reference, camera, and lighting collections;
- a humanoid-plus-tail armature template;
- an explicit coccyx-level `tail_root` locked to the rear pelvis midline;
- named action slots for every required motion;
- transparent, fixed-size render settings;
- the complete level 1-100 stage contract embedded in the scene.

## Validation

Validate current masters:

```sh
python3 tool/character_pipeline/validate_character_pipeline.py --masters-only
```

Validate a release export after all stages have been rendered:

```sh
python3 tool/character_pipeline/validate_character_pipeline.py
```

Validate the Blender scene anatomy and embedded contracts:

```sh
/Users/mattias/Applications/Blender.app/Contents/MacOS/Blender \
  --background \
  --python-exit-code 1 \
  --python tool/character_pipeline/validate_blender_scenes.py \
  -- \
  --repo-root "$PWD" \
  --source-root "$(dirname "$PWD")/GymRat-character-source"
```

Before rendering runtime emotes, repeat the same command with
`--require-render-ready`. This stricter gate also requires a rig-bound authored
mesh, one explicitly marked `gymrat_physique_driver` with the complete
`PHYSIQUE_001` through `PHYSIQUE_100` milestone shape-key set, and real bone
keyframes covering every pose action. Reference-only scenes or a model with
dummy/missing evolution stages must fail this gate and cannot be exported into
the app.

## Runtime 3D export

After all three models and their evolution shape keys pass visual review,
export one compact, rigged GLB per identity:

```sh
/Users/mattias/Applications/Blender.app/Contents/MacOS/Blender \
  --background \
  --python-exit-code 1 \
  --python tool/character_pipeline/export_runtime_glb.py \
  -- \
  --repo-root "$PWD" \
  --source-root "$(dirname "$PWD")/GymRat-character-source"
```

The exporter always runs the strict render-ready validation first and has no
incomplete-scene override. It exports the bound mesh, rig, all named actions,
and the approved physique morph targets while excluding reference planes,
cameras, and lights. Outputs stay in the external source directory under
`runtime_exports/` until the mobile renderer, file-size budget, and device
tests are approved.

A milestone is registered in Flutter only after all three identities, both
views, and all mandatory animation exports pass review. Missing or partial
stages deliberately remain unavailable.

## Human approval gates

The owner reviews four things; no Blender work is required from them:

1. the male pilot's locked identity and level-1 match;
2. the female and non-binary locked identities;
3. the level-100 silhouettes and the progression between milestones;
4. the final emote set in front and back views.

Everything between those gates is an authored production task and must not be
replaced by runtime scaling, cross-identity frames, or a newly invented rat.

The four mandatory emote actions are `double_biceps`, `chest_flex`,
`leg_pose`, and `triceps`. Each one must be authored in both camera views for
every identity, evolution stage, and complete purchasable appearance. Runtime
selection is random without immediate repetition and never adds a synthetic
body transform. Anatomical pose definitions and frame checkpoints live in
`docs/CHARACTER_EMOTE_POSE_CONTRACT.md`.

`author_double_biceps_pilot.py` authors the approved 48-frame front-view
double-biceps timing on one identity rig using auto-clamped Bezier curves and a
fixed root. It deliberately does not render or register sprites until the
external scene contains a bound authored character mesh and the render passes
the normal approval gate.

`author_motion_library.py` expands that foundation into the complete motion
contract for one identity: breathing, blink, articulated tail, all four front
and back emotes, victory, PB celebration, and recovery. Every curve uses
auto-clamped Bezier interpolation and leaves the root translation untouched.

`build_level1_model_pilot.py` creates an editable, armature-bound level-1
proportion model and projects only the approved front/back master textures onto
it. It marks the scene as requiring visual approval, so strict render-ready
validation continues to fail until form, joints, hands, feet, clothing, and
materials have passed review. The tool never writes runtime assets directly.
Use `--motion double_biceps --view front --frame 24 --render-preview <path>`
with `--dry-run` to render a repeatable pose checkpoint without modifying the
source scene. The pilot unifies the body surface and uses automatic heat
skinning so bends can be evaluated without gaps between rigid body sections.

Approved direction references are recorded in the external source directory's
`approvals.json`. The bootstrap verifies their SHA-256 fingerprints and embeds
them as locked, non-rendering Blender references. A direction approval does not
make an image runtime-ready; the full export contract still applies.
