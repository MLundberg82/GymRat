import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/core/localization/gymrat_localizations.dart';
import 'package:gymrat/features/profile/domain/training_profile.dart';
import 'package:gymrat/features/character/domain/rat_character_view.dart';
import 'package:gymrat/features/rewards/domain/gym_upgrade.dart';
import 'package:gymrat/features/rewards/presentation/level_up_celebration.dart';
import 'package:gymrat/features/rewards/presentation/pr_celebration.dart';
import 'package:gymrat/features/rewards/presentation/reward_sequence.dart';
import 'package:gymrat/features/workout/domain/workout_result.dart';
import 'package:gymrat/features/workout/presentation/workout_complete_screen.dart';

void main() {
  testWidgets('level-up silhouette uses the selected rat identity', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const <Locale>[Locale('en')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GymRatLocalizations.delegate,
        ],
        home: LevelUpCelebration(
          previousLevel: 3,
          newLevel: 4,
          isEvolution: false,
          gender: RatGender.female,
          characterView: RatCharacterView.back,
          appearanceId: 'missing-appearance',
          upgrade: GymUpgradeCatalog.forLevel(4),
        ),
      ),
    );
    await tester.pump();

    final assets = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => image.image)
        .whereType<AssetImage>()
        .map((image) => image.assetName)
        .toList();

    expect(assets, contains('assets/characters/female/level_01_back.png'));
    expect(assets, isNot(contains('assets/characters/male/level_01_back.png')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('workout complete forwards the equipped appearance to rewards', (
    tester,
  ) async {
    final result = WorkoutResult(
      workoutName: 'CHEST',
      completedAt: DateTime(2026, 9, 1),
      durationSeconds: 600,
      exercises: const <WorkoutExerciseResult>[],
      prs: const <WorkoutPR>[],
      xp: const XPBreakdown(
        baseXP: 20,
        activityXP: 0,
        volumeXP: 0,
        durationXP: 0,
        firstWorkoutXP: 0,
        consistencyXP: 0,
        prXP: 0,
        totalXP: 20,
      ),
      previousLevel: 1,
      newLevel: 1,
      totalXP: 20,
      streak: 1,
      milestoneUnlocked: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const <Locale>[Locale('en')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GymRatLocalizations.delegate,
        ],
        home: WorkoutCompleteScreen(
          result: result,
          appearanceId: 'equipped-test-appearance',
        ),
      ),
    );
    await tester.pump();

    final rewards = tester.widget<RewardSequence>(find.byType(RewardSequence));
    expect(rewards.appearanceId, 'equipped-test-appearance');
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });

  testWidgets('XP reward shows the persisted reward breakdown', (tester) async {
    final result = WorkoutResult(
      workoutName: 'CHEST',
      completedAt: DateTime(2026, 9, 1),
      durationSeconds: 2700,
      exercises: const <WorkoutExerciseResult>[],
      prs: const <WorkoutPR>[],
      xp: const XPBreakdown(
        baseXP: 20,
        activityXP: 12,
        volumeXP: 8,
        durationXP: 10,
        firstWorkoutXP: 15,
        consistencyXP: 9,
        prXP: 18,
        totalXP: 92,
      ),
      previousLevel: 1,
      newLevel: 1,
      totalXP: 92,
      streak: 2,
      milestoneUnlocked: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const <Locale>[Locale('en')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GymRatLocalizations.delegate,
        ],
        home: XpRewardStage(
          result: result,
          duration: const Duration(milliseconds: 300),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('+92 XP'), findsOneWidget);
    expect(find.text('+57'), findsOneWidget);
    expect(find.text('+8'), findsOneWidget);
    expect(find.text('+9'), findsOneWidget);
    expect(find.text('+18'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('PB celebration shows the real improvement and XP reward', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const <Locale>[Locale('en')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GymRatLocalizations.delegate,
        ],
        home: const PrCelebration(
          pr: WorkoutPR(
            exercise: 'Bench Press',
            newWeight: 85,
            previousBest: 80,
          ),
          position: 1,
          total: 1,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1600));

    expect(find.text('▲ +5 KG'), findsOneWidget);
    expect(find.text('+18 XP'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 1400));
  });
}
