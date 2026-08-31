import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/features/armory/data/rat_inventory_store.dart';
import 'package:gymrat/features/armory/domain/rat_item.dart';
import 'package:gymrat/features/coach/domain/coach_recommendation.dart';
import 'package:gymrat/features/evolution/domain/evolution_milestones.dart';
import 'package:gymrat/features/profile/data/training_profile_store.dart';
import 'package:gymrat/features/profile/domain/training_profile.dart';
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

  test('credits buy and auto-equip a cosmetic item', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    for (var index = 0; index < 6; index++) {
      await RatInventoryStore.claimQuest('claim-$index', 10);
    }
    final item = RatItemCatalog.byId('shadow_hood')!;

    final result = await RatInventoryStore.purchase(item, level: 1);
    final state = await RatInventoryStore.load();

    expect(result, RatItemPurchaseResult.purchased);
    expect(state.credits, 0);
    expect(state.ownedItems, contains(item.id));
    expect(state.loadoutForLevel(1)[RatItemSlot.head]?.id, item.id);
  });

  test('level 50 produces an Olympia-sized rat and final item', () {
    expect(
      EvolutionMilestones.widthScaleForLevel(50),
      greaterThanOrEqualTo(1.6),
    );
    expect(
      EvolutionMilestones.heightScaleForLevel(50),
      greaterThanOrEqualTo(1.2),
    );
    expect(RatItemCatalog.forLevel(50)?.id, 'olympia_aura');
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
  });
}

WorkoutHistoryEntry _workout(String name, DateTime completedAt) {
  return WorkoutHistoryEntry(
    id: '$name-${completedAt.millisecondsSinceEpoch}',
    workoutName: name,
    completedAt: completedAt,
    durationSeconds: 1800,
    isWalk: false,
    exercises: const <WorkoutExerciseResult>[],
  );
}
