import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/features/armory/data/rat_inventory_store.dart';
import 'package:gymrat/features/armory/domain/rat_item.dart';
import 'package:gymrat/features/coach/domain/coach_recommendation.dart';
import 'package:gymrat/features/character/domain/rat_appearance.dart';
import 'package:gymrat/features/character/domain/rat_character_view.dart';
import 'package:gymrat/features/evolution/domain/evolution_milestones.dart';
import 'package:gymrat/features/profile/data/training_profile_store.dart';
import 'package:gymrat/features/profile/domain/training_profile.dart';
import 'package:gymrat/features/premium/data/premium_access.dart';
import 'package:gymrat/features/workout/data/workout_session_store.dart';
import 'package:gymrat/features/workout/domain/workout_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const profile = TrainingProfile(
    gender: RatGender.female,
    experience: TrainingExperience.advanced,
    heightCm: 168,
    weightKg: 68.5,
    sessionsPerWeek: 4,
    goal: TrainingGoal.buildMuscle,
  );

  test('training profile persists all onboarding choices', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await TrainingProfileStore.save(profile);
    TrainingProfileStore.profile.value = null;

    await TrainingProfileStore.initialize();

    expect(TrainingProfileStore.profile.value?.gender, RatGender.female);
    expect(
      TrainingProfileStore.profile.value?.experience,
      TrainingExperience.advanced,
    );
    expect(TrainingProfileStore.profile.value?.heightCm, 168);
    expect(TrainingProfileStore.profile.value?.weightKg, 68.5);
    expect(TrainingProfileStore.profile.value?.sessionsPerWeek, 4);
    expect(TrainingProfileStore.profile.value?.goal, TrainingGoal.buildMuscle);
  });

  test('quest rewards cannot be claimed twice', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    expect(await RatInventoryStore.claimQuest('daily-test', 15), isTrue);
    expect(await RatInventoryStore.claimQuest('daily-test', 15), isFalse);

    final state = await RatInventoryStore.load();
    expect(state.credits, 15);
    expect(state.claimedQuests, contains('daily-test'));
  });

  test('selected character view persists across app launches', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await RatInventoryStore.setCharacterView(RatCharacterView.back);
    final restored = await RatInventoryStore.load();

    expect(restored.characterView, RatCharacterView.back);
    expect(restored.equippedAppearanceId, RatAppearanceCatalog.baseId);
  });

  test(
    'incomplete cosmetic cannot spend credits or change appearance',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      for (var index = 0; index < 6; index++) {
        await RatInventoryStore.claimQuest('claim-$index', 10);
      }
      final item = RatItemCatalog.byId('shadow_hood')!;

      final result = await RatInventoryStore.purchase(item, level: 1);
      final state = await RatInventoryStore.load();

      expect(result, RatItemPurchaseResult.appearanceUnavailable);
      expect(state.credits, 60);
      expect(state.ownedItems, isNot(contains(item.id)));
      expect(state.equippedAppearanceId, RatAppearanceCatalog.baseId);
    },
  );

  test('missing level 100 art never fakes an Olympia physique by scaling', () {
    expect(
      RatAppearanceCatalog.approvedStageForLevel(
        appearanceId: RatAppearanceCatalog.baseId,
        level: 100,
      ),
      1,
    );
    expect(
      RatAppearanceCatalog.hasDistinctStageAtLevel(
        appearanceId: RatAppearanceCatalog.baseId,
        level: 100,
      ),
      isFalse,
    );
    expect(RatItemCatalog.forLevel(50)?.id, 'rank_mark_50');
  });

  test('unfinished wearables are concepts, not owned level rewards', () {
    const inventory = RatInventoryState();
    final headband = RatItemCatalog.byId('rookie_headband')!;

    expect(headband.isConcept, isTrue);
    expect(inventory.owns(headband, 50), isFalse);
    expect(RatItemCatalog.forLevel(2)?.id, 'rank_mark_2');
  });

  test('evolution roadmap uses exact progression thresholds', () {
    expect(WorkoutSessionStore.totalXPToReachLevel(1), 0);
    expect(WorkoutSessionStore.totalXPToReachLevel(2), 90);
    expect(WorkoutSessionStore.totalXPToReachLevel(5), 480);
    expect(
      WorkoutSessionStore.levelFromXP(
        WorkoutSessionStore.totalXPToReachLevel(10),
      ),
      10,
    );
    expect(EvolutionMilestones.nextMilestoneAfter(1), 5);
    expect(EvolutionMilestones.nextMilestoneAfter(5), 10);
    expect(EvolutionMilestones.nextMilestoneAfter(50), 60);
    expect(EvolutionMilestones.nextMilestoneAfter(99), 100);
    expect(EvolutionMilestones.nextMilestoneAfter(100), isNull);
  });

  test('every level after level one unlocks a character reward', () {
    for (var level = 2; level <= 50; level++) {
      expect(
        RatItemCatalog.itemsForLevel(level),
        isNotEmpty,
        reason: 'level $level must have a reward beyond the gym upgrade',
      );
      expect(
        RatItemCatalog.itemsForLevel(level),
        contains(
          predicate<RatItem>((item) => item.slot == RatItemSlot.collectible),
        ),
      );
    }
  });

  test('store cosmetics cover clothing and footwear slots', () {
    expect(
      RatItemCatalog.byId('graphite_cap'),
      isA<RatItem>()
          .having((item) => item.slot, 'slot', RatItemSlot.head)
          .having(
            (item) => item.previewAssetPath,
            'previewAssetPath',
            'assets/items/graphite_cap.png',
          ),
    );
    expect(
      RatItemCatalog.byId('founders_tee'),
      isA<RatItem>()
          .having((item) => item.slot, 'slot', RatItemSlot.top)
          .having(
            (item) => item.previewAssetPath,
            'previewAssetPath',
            isNotNull,
          )
          .having(
            (item) => item.hasCompleteAppearance,
            'hasCompleteAppearance',
            isFalse,
          ),
    );
    expect(RatItemCatalog.byId('champion_joggers')?.slot, RatItemSlot.bottom);
    expect(RatItemCatalog.byId('neon_trainers')?.slot, RatItemSlot.feet);
    expect(
      RatItemCatalog.byStoreProductId('gymrat.neon_trainers')?.id,
      'neon_trainers',
    );
  });

  test('base appearance has the complete identity and view matrix', () {
    expect(RatAppearanceCatalog.base.isComplete, isTrue);
    for (final gender in RatGender.values) {
      final assets = RatAppearanceCatalog.base.assetsByGender[gender];
      expect(assets, isNotNull);
      expect(assets!.front, isNotEmpty);
      expect(assets.back, isNotEmpty);
    }
  });

  test('legacy slot loadout migrates safely to the base appearance', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'gymrat-rat-inventory-v1':
          '{"version":1,"credits":25,"claimedQuests":["q1"],'
          '"ownedItems":["graphite_cap"],'
          '"equipped":{"head":"graphite_cap"}}',
    });

    final state = await RatInventoryStore.load();

    expect(state.credits, 25);
    expect(state.claimedQuests, contains('q1'));
    expect(state.ownedItems, contains('graphite_cap'));
    expect(state.equippedAppearanceId, RatAppearanceCatalog.baseId);
  });

  test('free history is capped while premium keeps every session', () {
    final workouts = List.generate(
      14,
      (index) => _workout('CHEST', DateTime(2026, 8, index + 1)),
    ).reversed.toList();
    final history = TrainingHistorySnapshot(
      workouts: workouts,
      personalBests: const [],
    );

    expect(
      PremiumAccess.visibleHistory(history, isPremium: false).workouts,
      hasLength(PremiumAccess.freeHistoryLimit),
    );
    expect(
      PremiumAccess.visibleHistory(history, isPremium: true).workouts,
      hasLength(14),
    );
  });

  test('changing rat identity preserves training profile data', () {
    final changed = profile.copyWith(gender: RatGender.nonBinary);

    expect(changed.gender, RatGender.nonBinary);
    expect(changed.experience, profile.experience);
    expect(changed.heightCm, profile.heightCm);
    expect(changed.weightKg, profile.weightKg);
    expect(changed.sessionsPerWeek, profile.sessionsPerWeek);
    expect(changed.goal, profile.goal);
  });

  test('coach rotates toward the least recently trained area', () {
    final history = TrainingHistorySnapshot(
      personalBests: const [],
      workouts: [
        _workout('CHEST', DateTime(2026, 8, 30)),
        _workout('BACK', DateTime(2026, 8, 29)),
        _workout('LEGS', DateTime(2026, 8, 28)),
      ],
    );

    final recommendation = CoachRecommendationEngine.build(
      profile: profile,
      history: history,
      now: DateTime(2026, 8, 31, 10),
    );

    expect(recommendation.workoutName, 'ARMS');
    expect(recommendation.setRange, '4–5');
    expect(recommendation.repRange, '8–12');
    expect(recommendation.weeklyTarget, 4);
    expect(recommendation.weeklyRemaining, 4);
    expect(recommendation.rotationQueue.first, 'ARMS');
    expect(recommendation.missionMode, CoachMissionMode.strength);
  });

  test('coach rotation is independent of history storage order', () {
    final history = TrainingHistorySnapshot(
      personalBests: const [],
      workouts: [
        _workout('CHEST', DateTime(2026, 8, 10)),
        _workout('BACK', DateTime(2026, 8, 30)),
        _workout('LEGS', DateTime(2026, 8, 29)),
        _workout('ARMS', DateTime(2026, 8, 28)),
        _workout('CHEST', DateTime(2026, 8, 31)),
      ],
    );

    final recommendation = CoachRecommendationEngine.build(
      profile: profile,
      history: history,
      now: DateTime(2026, 9, 2, 10),
    );

    expect(recommendation.workoutName, 'ARMS');
    expect(recommendation.rotationQueue, ['ARMS', 'LEGS', 'BACK', 'CHEST']);
    expect(recommendation.recoveryDays, 5);
  });

  test('coach protects recovery after the weekly target is complete', () {
    final history = TrainingHistorySnapshot(
      personalBests: const [],
      workouts: [
        _workout('CHEST', DateTime(2026, 8, 31, 8)),
        _workout('BACK', DateTime(2026, 8, 31, 18)),
        _workout('LEGS', DateTime(2026, 9, 1, 8)),
        _workout('ARMS', DateTime(2026, 9, 1, 18)),
      ],
    );

    final recommendation = CoachRecommendationEngine.build(
      profile: profile,
      history: history,
      now: DateTime(2026, 9, 2, 10),
    );

    expect(recommendation.workoutName, 'WALK');
    expect(recommendation.weeklyCompleted, 4);
    expect(recommendation.weeklyRemaining, 0);
    expect(recommendation.recoveryRecommended, isTrue);
    expect(recommendation.missionMode, CoachMissionMode.activeRecovery);
    expect(recommendation.reasonKey, 'coachWeeklyTargetReachedReason');
  });

  test('a walk does not replace a safe strength mission', () {
    final history = TrainingHistorySnapshot(
      personalBests: const [],
      workouts: [
        WorkoutHistoryEntry(
          id: 'walk-today',
          workoutName: 'WALK',
          completedAt: DateTime(2026, 9, 2, 8),
          durationSeconds: 1800,
          isWalk: true,
          exercises: const [],
        ),
      ],
    );

    final recommendation = CoachRecommendationEngine.build(
      profile: profile,
      history: history,
      now: DateTime(2026, 9, 2, 10),
    );

    expect(recommendation.workoutName, 'CHEST');
    expect(recommendation.weeklyRemaining, 3);
    expect(recommendation.recoveryRecommended, isFalse);
  });

  test('coach protects recovery after a recently rated hard session', () {
    final history = TrainingHistorySnapshot(
      personalBests: const [],
      workouts: [_workout('LEGS', DateTime(2026, 9, 1, 20), effortRating: 5)],
    );

    final recommendation = CoachRecommendationEngine.build(
      profile: profile,
      history: history,
      now: DateTime(2026, 9, 2, 10),
    );

    expect(recommendation.workoutName, 'WALK');
    expect(recommendation.recoveryRecommended, isTrue);
    expect(recommendation.reasonKey, 'coachEffortRecoveryReason');
  });

  test('coach reports volume change without prescribing more load', () {
    final history = TrainingHistorySnapshot(
      personalBests: const [],
      workouts: [
        _volumeWorkout('CHEST', DateTime(2026, 8, 20), 120),
        _workout('BACK', DateTime(2026, 8, 25)),
        _workout('LEGS', DateTime(2026, 8, 26)),
        _workout('ARMS', DateTime(2026, 8, 27)),
        _volumeWorkout('CHEST', DateTime(2026, 8, 10), 100),
      ],
    );

    final recommendation = CoachRecommendationEngine.build(
      profile: profile,
      history: history,
      now: DateTime(2026, 8, 31, 10),
    );

    expect(recommendation.workoutName, 'CHEST');
    expect(recommendation.latestVolume, 120);
    expect(recommendation.volumeChangePercent, closeTo(20, .001));
  });
}

WorkoutHistoryEntry _workout(
  String name,
  DateTime completedAt, {
  int? effortRating,
}) {
  return WorkoutHistoryEntry(
    id: '$name-${completedAt.millisecondsSinceEpoch}',
    workoutName: name,
    completedAt: completedAt,
    durationSeconds: 1800,
    isWalk: false,
    exercises: const <WorkoutExerciseResult>[],
    effortRating: effortRating,
  );
}

WorkoutHistoryEntry _volumeWorkout(
  String name,
  DateTime completedAt,
  double volume,
) {
  return WorkoutHistoryEntry(
    id: '$name-${completedAt.millisecondsSinceEpoch}',
    workoutName: name,
    completedAt: completedAt,
    durationSeconds: 1800,
    isWalk: false,
    exercises: [
      WorkoutExerciseResult(
        name: '$name exercise',
        muscleGroup: name.toLowerCase(),
        sets: [WorkoutSetResult(weight: volume, reps: 1)],
      ),
    ],
  );
}
