# GymRat Reward System v1

This source package adds the post-workout reward sequence without changing the
existing workout persistence, XP calculation, PB detection, timers, or hub flow.

## Included

- PB celebrations shown one at a time
- Animated XP reward stage
- Level-up celebration
- Stronger milestone/evolution level-up variant
- Gold particles, flash, scale/punch animations, and haptics
- Localized reward UI in English, Swedish, Spanish, Russian, and Chinese
- Workout summary after the reward sequence

## Automatic installation on the GymRat Windows computer

1. Extract this ZIP file to a normal folder.
2. Open PowerShell in the extracted folder.
3. Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\install_reward_v1.ps1
```

The installer verifies the GymRat and Flutter paths, backs up replaced files to
the Desktop, installs only the Reward v1 files, runs `flutter pub get`, and runs
`flutter analyze`.

After a successful analysis, open the existing GymRat project in Android Studio
and run it in the emulator.
