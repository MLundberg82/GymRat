# GymRat mobile release readiness

This checklist is the source of truth for local device builds and the first
store-connected release candidate. Never add signing credentials, populated
`key.properties`, RevenueCat keys, or store secrets to the repository.

## Android local device build

1. Accept the Android SDK licenses with `flutter doctor --android-licenses`.
2. Enable developer options and USB debugging on the phone.
3. Confirm the phone appears in `flutter devices`.
4. Run `flutter analyze`, `flutter test`, and `flutter build apk --debug`.
5. Install `build/app/outputs/flutter-apk/app-debug.apk` with
   `flutter install -d <device-id>` or `adb install -r <apk-path>`.
6. Start from a clean install and execute the mobile acceptance matrix below.

The debug APK is for local testing only. A store release requires a private
Android upload keystore configured from `android/key.properties.example`.

## iOS preparation and first Mac verification

Shared Dart code, RevenueCat integration, localized metadata, app icons, and
the launch screen are checked in. On macOS:

1. Install the stable Flutter SDK and current Xcode, then run
   `sudo xcodebuild -runFirstLaunch` and `flutter doctor -v`.
2. Run `flutter pub get`, `flutter analyze`, and `flutter test`.
3. Run `flutter build ios --debug --no-codesign`.
4. Open `ios/Runner.xcworkspace`, select the Apple development team, and
   verify the production bundle identifier.
5. Test a current iPhone simulator before installing on a physical iPhone.
6. Verify StoreKit purchases and Restore Purchases with an App Store sandbox
   account before any TestFlight upload.

## RevenueCat and store configuration

The app reads public RevenueCat SDK keys from `REVENUECAT_APPLE_API_KEY` and
`REVENUECAT_GOOGLE_API_KEY` build-time defines. The dashboard must provide:

- one `premium` entitlement attached to the subscription products;
- a current offering containing the approved subscription packages;
- one entitlement per permanent cosmetic appearance product;
- matching product identifiers in App Store Connect and Google Play Console;
- sandbox/test accounts for purchase, cancellation, renewal, expiry, offline,
  reinstall, and restore scenarios.

Do not publish a cosmetic product until its complete authored appearance matrix
passes the character asset contract. The app intentionally hides and blocks
incomplete appearances.

## Mobile acceptance matrix

Run the following on Android and iOS, on narrow and large phones:

- first launch in every supported system language;
- onboarding for male, female, and non-binary identities;
- front/back selection retained after relaunch;
- rat power-flex and breathing without image drift;
- Chest, Back, Legs, Arms, and Walk from preview through completion;
- active strength workout restored after forced app termination;
- baseline session awards no PB, followed by a genuine PB reward;
- level-up and milestone evolution in both character views;
- category, exercise, PB, estimated-strength, and volume charts;
- clickable hub record stations and their full progress route;
- Premium locked, purchased, expired, offline, and restored states;
- Armory Credits and quest claims remain idempotent;
- local data export and confirmed deletion return to onboarding;
- safe areas, text scaling, screen-reader labels, reduced motion, interruptions,
  backgrounding, and cold relaunch.

## Character content gate

The runtime is ready for stages 1, 5, 10, 15, 20, 30, 40, and 50. Only the
approved level-1 identity/view matrix currently exists. Missing stages retain
the correct identity and view while progression scaling supplies visible
growth. A milestone becomes shippable only when all six human-reviewed renders
exist and pass `test/character_asset_contract_test.dart`.
