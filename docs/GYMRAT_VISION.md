# GymRat vision

## Product identity

GymRat is a Flutter training app built for Android first, with iOS support
planned later. It should feel like an addictive premium RPG powered by real
training progress. It is not a conventional wellness app: workouts are the
gameplay loop, consistency builds the character and gym, and rewards make
progress feel immediate and valuable.

The product should be intense, aspirational, and premium without becoming
cluttered. Functionality and progression must remain understandable even when
reward moments are visually dramatic.

## Visual system

- Graphite and near-black are the foundation for backgrounds and surfaces.
- Green represents workouts, primary actions, and forward movement.
- Gold represents XP, personal bests, level-ups, rewards, and evolution.
- Purple represents Premium.
- The hub is clean and hero-first, with the rat and gym as the visual focus.
- The app does not use bottom navigation. Secondary destinations live in the
  hamburger menu.
- Working layout, navigation, timing, and flows should not be redesigned unless
  there is a specific product, accessibility, or runtime-safety reason.

## Core journey

The canonical workout loop is:

`Hub -> Choose Workout -> Preview -> Active Workout/Walk -> rewards -> Workout Complete -> Hub`

The free workout presets are:

- Chest
- Back
- Legs
- Arms
- Walk

Strength presets use the active workout flow. Walk uses its dedicated active
walk flow. Completing either persists the session, calculates progression,
plays earned rewards, shows the workout summary, and returns to a refreshed
hub.

## Progression and rewards

Persistence is local through `shared_preferences`. `WorkoutSessionStore` owns
workout history, XP, level calculation, streaks, and personal-best comparison.
Changes to stored data must remain backward-compatible.

A user's first recorded result for an exercise establishes the baseline. It is
never awarded as a personal best. A PB is awarded only when a later result is
strictly greater than the stored baseline.

Evolution milestones are fixed at levels 5, 10, 15, 20, 30, 40, and 50. The
same accepted rat master asset is used across stages until real, approved
milestone assets are available. The rat must not be regenerated with AI.

Reward and evolution animation may use overshooting curves for bounce, scale,
and movement. Values passed to APIs with bounded contracts, including opacity
and alpha, must be independently constrained to their valid ranges without
flattening the intended motion.

## Localization

System language is the default. A user-selected language is persisted and may
override it. All new important user-facing UI text must be added to and read
through `GymRatLocalizations`; do not introduce new important hard-coded UI
copy.

The current localization infrastructure supports English, Swedish, Spanish,
Russian, and Chinese. Some legacy screens still contain hard-coded copy; new
work must not expand that debt.

## Verified implementation baseline

As verified from the repository on 2026-08-28:

- The hub is hero-first and uses an end drawer instead of bottom navigation.
- `WorkoutPresets.free` contains Chest, Back, Legs, Arms, and Walk.
- Preview routes strength workouts to `ActiveWorkoutScreen` and walking to
  `WalkWorkoutScreen`.
- `WorkoutCompleteScreen` runs `RewardSequence`, then shows the workout summary,
  then returns to a refreshed `HubScreen`.
- `WorkoutSessionStore` persists progress through `shared_preferences` and uses
  prior history to distinguish a baseline from a later PB.
- `EvolutionMilestones.unlockLevels` contains 5, 10, 15, 20, 30, 40, and 50.
- `GymRatAssets.maleForLevel` currently resolves every level to the accepted
  `maleLevel1` master.
- The theme already defines the graphite/black, action green, reward gold, and
  Premium purple roles.

## Engineering standard

GymRat code should be production-safe, modular, testable, and backward-
compatible. Preserve existing user work and keep changes narrowly scoped.
Before any push, format changed Dart files and require `flutter analyze`,
`flutter test`, and `flutter build apk --debug` to pass. Never push a failing
state.
