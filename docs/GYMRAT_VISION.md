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

Quest contracts award Armory Credits through an explicit claim action. Claims
are idempotent and persisted with the inventory state so the same contract can
never be collected twice. Armory Credits are earned through training and are
used only for standard cosmetic items; they are not sold for money. Other rat
items unlock directly from specific level-ups. Paid cosmetics remain direct
store products and must not be confused with earned progression.

## Player profile, character, and coaching

The first launch creates a durable training profile containing:

- rat identity: male, female, or non-binary;
- training experience: beginner, intermediate, advanced, or expert;
- intended sessions per week;
- height and weight;
- primary goal: muscle, strength, fat loss, or general fitness.

The profile can be edited later and is the input for future Premium coaching.
Gender identity must not change workout access, XP, rewards, or progression.
Male, female, and non-binary now each have approved level-1 front and back
masters. Every later stage must preserve its own approved identity and must
never be generated as a new rat from scratch. Missing milestone assets must
fall back safely to the latest complete approved stage.

The rat grows at each evolution milestone. Growth is modest at early levels and
ends in an intentionally massive Mr Olympia-scale silhouette at level 50.
Cosmetics are never positioned over the rat at runtime. A wearable look is
released only as a complete, authored full-character appearance covering male,
female, and non-binary identities from both the front and back. Individual
items may exist as collection rewards or separate concept art before that
matrix is complete, but they cannot be equipped, sold, or composited onto the
rat. The selected complete appearance is persisted independently from training
progress. See `docs/CHARACTER_APPEARANCE_PIPELINE.md`.
The milestone physique, file, and review contract is defined in
`docs/CHARACTER_EVOLUTION_ART_DIRECTION.md`.

GymRat Premium Coach uses the training profile and persisted session history to
recommend the next safe workout rotation, set and repetition ranges, recovery,
and weekly frequency. Its weekly campaign shows completed and remaining
missions, while recovery windows and volume changes explain the recommendation
without prescribing a load increase. Premium users can enter the matching free
workout preview directly from the recommendation. Recommendations must never
prescribe medical treatment, force personal records, or increase load from
assumptions. Pain, illness, and professional medical guidance always override
the recommendation engine.

## Verified implementation baseline

As verified from the repository on 2026-09-02:

- The hub is hero-first and uses an end drawer instead of bottom navigation.
- `WorkoutPresets.free` contains Chest, Back, Legs, Arms, and Walk.
- Preview routes strength workouts to `ActiveWorkoutScreen` and walking to
  `WalkWorkoutScreen`.
- `WorkoutCompleteScreen` runs `RewardSequence`, then shows the workout summary,
  then returns to a refreshed `HubScreen`.
- `WorkoutSessionStore` persists progress through `shared_preferences` and uses
  prior history to distinguish a baseline from a later PB.
- `EvolutionMilestones.unlockLevels` contains 5, 10, 15, 20, 30, 40, and 50.
- Male, female, and non-binary level-1 front/back masters are active, and the
  stage-aware appearance catalog falls back to the latest complete approved
  stage whenever a later milestone matrix is missing.
- Premium Coach derives an order-independent mission rotation, weekly campaign,
  recovery signal, and volume trend from the training profile and persisted
  history. Guided missions carry the conservative set count and repetition
  range into workout preview and the active workout without inventing a load
  target.
- Progress shows the exact XP distance to the next evolution milestone and its
  featured collection reward. Level 50 is represented as the completed final
  form rather than a fictional next stage.
- Workout and exercise names remain stable canonical values in persisted
  history and PB calculations, while every presentation layer resolves them
  through `GymRatLocalizations` in all five supported languages.
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

## Store release signing

Android release builds must never fall back to the debug signing identity. A
developer or CI environment may copy `android/key.properties.example` to the
ignored `android/key.properties` and provide the real upload-keystore path and
credentials locally. Keystores and populated credentials must never be
committed. Without that local file, debug builds remain available while the
release variant stays unsigned.

iOS signing remains owned by the selected Apple development team in Xcode. The
RevenueCat public SDK keys are build-time values and are independent of native
code signing on both platforms.

## Engineering standard

GymRat code should be production-safe, modular, testable, and backward-
compatible. Preserve existing user work and keep changes narrowly scoped.
Before any push, format changed Dart files and require `flutter analyze`,
`flutter test`, and `flutter build apk --debug` to pass. Never push a failing
state.
