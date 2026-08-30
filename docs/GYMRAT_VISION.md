# GymRat vision

## Product identity

GymRat is a Flutter training app built for Android first, with feature-level
code parity maintained for iOS. Native iOS builds, signing, and device checks
are completed on macOS/Xcode. It should feel like an addictive premium RPG
powered by real training progress. It is not a conventional wellness app:
workouts are the gameplay loop, consistency builds the character and gym, and
rewards make progress feel immediate and valuable.

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

## Missions and Gym Armory

Missions turn persisted workout history into daily contracts and weekly
campaigns. They must reward sustainable training behavior and never pressure a
user to chase unsafe weight, duration, or personal-best targets. Initial quest
progress is derived from completed sessions, duration, and exercise count, so
the board remains consistent with the training archive and does not create a
second source of truth.

Gym Armory is both the collection of gym upgrades earned through levels and the
future storefront for GymRat Premium and cosmetic rat items. Earned progression
must remain distinct from paid content. Paid digital content uses Apple In-App
Purchase on iOS and Google Play Billing on Android, with RevenueCat providing a
shared Flutter integration for offerings, purchases, entitlements, and restore.
The app must remain fully usable when store configuration or connectivity is
unavailable.

RevenueCat public SDK keys are supplied at build time and are never committed:

- `REVENUECAT_APPLE_API_KEY`
- `REVENUECAT_GOOGLE_API_KEY`

Products and localized prices come from the official stores through the active
RevenueCat offering. Do not hard-code prices or ship fictional store products.
Premium should use a subscription entitlement. Permanent cosmetic purchases
should use non-consumable products attached to the entitlement that unlocks the
item. Every restorable purchase flow must expose Restore Purchases.

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
- The iOS runner targets iOS 15, uses Flutter's Swift Package Manager plugin
  integration, and declares the same five supported languages as the app.

## iOS verification on macOS

The shared Flutter code must remain free of unnecessary Android-only behavior.
When a macOS/Xcode environment is available, verify iOS with:

1. Run `flutter doctor -v` and resolve every Xcode/CocoaPods warning that
   applies to the installed Flutter toolchain.
2. Run `flutter pub get`, `flutter analyze`, and `flutter test`.
3. Run `flutter build ios --debug --no-codesign`.
4. Open `ios/Runner.xcworkspace`, select the correct Apple development team,
   and confirm the production bundle identifier before signing.
5. Test a current iPhone simulator and a physical iPhone, including safe-area
   layout, system-language selection, persistence after relaunch, the complete
   workout/reward loop, history details, and personal-best records.

The checked-in launcher icon sets still use the generated Flutter placeholder.
The approved shield-and-barbell source master is preserved at
`assets/branding/gymrat_app_icon_master_v1.png`; keep it unchanged until the
platform icon exports are deliberately generated and reviewed. Never generate
the rat with AI for this purpose.

## Engineering standard

GymRat code should be production-safe, modular, testable, and backward-
compatible. Preserve existing user work and keep changes narrowly scoped.
Before any push, format changed Dart files and require `flutter analyze`,
`flutter test`, and `flutter build apk --debug` to pass. Never push a failing
state.
