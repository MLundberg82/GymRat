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

Approved direction references are recorded in the external source directory's
`approvals.json`. The bootstrap verifies their SHA-256 fingerprints and embeds
them as locked, non-rendering Blender references. A direction approval does not
make an image runtime-ready; the full export contract still applies.
