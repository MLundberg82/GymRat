# GymRat

GymRat is a gamified Flutter training app that turns workouts, consistency,
personal bests, XP, level-ups, and evolution into a premium RPG-style
progression loop. Android is the first verified target, while shared features
are kept at code parity with iOS for native verification on macOS/Xcode.

The durable product and engineering direction lives in
[`docs/GYMRAT_VISION.md`](docs/GYMRAT_VISION.md). Repository-wide contribution
rules live in [`AGENTS.md`](AGENTS.md).

## Current experience

The main journey is:

`Hub -> Choose Workout -> Preview -> Active Workout/Walk -> rewards -> Workout Complete -> Hub`

The current free presets are Chest, Back, Legs, Arms, and Walk. Completed
sessions persist locally through `shared_preferences`; `WorkoutSessionStore`
owns history, XP, levels, streaks, and personal-best comparison.

The app supports English, Swedish, Spanish, Russian, and Chinese, with system
language used by default. Evolution milestones are levels 5, 10, 15, 20, 30,
40, and 50.

Completed sessions are also available through the Training History combat log.
Its Records tab derives earned personal bests from persisted history: the first
result remains a baseline, and only a later improvement unlocks a record.

GymRat Premium Coach turns the training profile and workout archive into a safe
weekly mission rotation with recovery and volume signals. A recommended mission
opens the matching workout preview and carries its set and repetition guidance
into the active session without automatically increasing weight. The Progress
screen tracks exact XP distance and the featured reward for the next evolution.

## Project structure

- `lib/app`: application shell and routing entry point
- `lib/core`: assets, localization, and theme primitives
- `lib/features`: feature modules for hub, workouts, rewards, evolution,
  character, profile, and progress
- `test`: widget and domain regression tests
- `docs`: durable product documentation

## Local development

Use the Flutter SDK configured for the project, then run:

```text
flutter pub get
flutter run
```

Before pushing a change, all quality gates must pass:

```text
dart format <changed Dart files>
flutter analyze
flutter test
flutter build apk --debug
```

Do not commit local tooling state such as `.codex/`, credentials, secrets,
caches, or generated build outputs.
