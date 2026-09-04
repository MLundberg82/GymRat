# GymRat repository instructions

These instructions apply to the entire repository.

## Product direction

- GymRat is a Flutter app for Android first. Keep every feature at code parity
  with iOS; native iOS builds and signing are verified on macOS/Xcode.
- The experience must feel like an addictive premium training RPG, not a
  generic wellness app.
- Preserve the visual language: graphite/black surfaces, green for workouts
  and actions, gold for XP, personal bests, level-ups, rewards, and evolution,
  and purple for Premium.
- Keep the hub clean, hero-first, and free of bottom navigation. Navigation is
  through the hamburger menu.
- Do not change working layouts or flows without a concrete product or safety
  reason. Preserve timing, spacing, assets, and interaction patterns unless the
  task explicitly requires a change.

See `docs/GYMRAT_VISION.md` for the durable product and architecture vision.

## Core behavior that must remain compatible

- The workout flow is Hub -> Choose Workout -> Preview -> Active Workout/Walk
  -> rewards -> Workout Complete -> Hub.
- The free presets are Chest, Back, Legs, Arms, and Walk.
- Route all new important user-facing text through `GymRatLocalizations`.
  System language remains the default unless the user explicitly selects a
  language.
- Persistence uses `shared_preferences`, with workout and progression state
  owned by `WorkoutSessionStore`.
- A first recorded result establishes the personal-best baseline. It must not
  award a PB. Only a later result above that baseline awards a PB.
- Evolution milestones are levels 5, 10, 15, 20, 30, 40, and 50.
- Treat the accepted level-1 rat assets as identity masters for their gender and
  view. Generated motion frames and future milestone variants may derive from
  those masters only when gender presentation, face, palette, canvas alignment,
  and true alpha transparency are verified. Never fake muscular growth by
  enlarging the same raster, and never activate a milestone until its complete
  front/back matrix for male, female, and non-binary identities is approved.
- First launch collects rat identity, training experience, intended weekly
  frequency, height, weight, and training goal. Identity options are male,
  female, and non-binary; they never change workout access or progression.
- The rat grows through evolution stages toward a deliberately massive level-50
  physique. Cosmetic items may unlock from level-ups or Armory Credits, but
  must remain separate from workout performance.
- Premium coaching may use the saved profile and workout history for safe
  rotation, volume, and recovery guidance. It must never force PBs, prescribe
  medical treatment, or infer aggressive load increases.

## Engineering rules

- Write production-safe, modular, backward-compatible Dart and Flutter code.
- Preserve the user's existing changes and keep diffs scoped to the task.
- Do not commit `.codex/`, credentials, secrets, local caches, generated build
  outputs, or unrelated files.
- Do not solve test or analyzer failures by weakening coverage, suppressing
  diagnostics, or changing product behavior without justification.
- Before pushing, run:

  1. `dart format` on all changed Dart files.
  2. `flutter analyze`.
  3. `flutter test`.
  4. `flutter build apk --debug`.

- Never push when any required check fails. Report the exact failure instead.
- When all checks pass, create clear commits containing only relevant files and
  push the intended branch.
