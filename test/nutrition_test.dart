import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/features/nutrition/data/nutrition_store.dart';
import 'package:gymrat/features/nutrition/domain/nutrition_models.dart';
import 'package:gymrat/features/profile/domain/training_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const profile = TrainingProfile(
    gender: RatGender.male,
    experience: TrainingExperience.intermediate,
    heightCm: 180,
    weightKg: 80,
    sessionsPerWeek: 4,
    goal: TrainingGoal.buildMuscle,
    ageYears: 30,
  );

  group('NutritionCalculator', () {
    test('requires age before returning a personal target', () {
      expect(NutritionCalculator.targetsFor(profile.copyWith()), isNotNull);
      const legacyProfile = TrainingProfile(
        gender: RatGender.male,
        experience: TrainingExperience.intermediate,
        heightCm: 180,
        weightKg: 80,
        sessionsPerWeek: 4,
        goal: TrainingGoal.buildMuscle,
      );
      expect(NutritionCalculator.targetsFor(legacyProfile), isNull);
      expect(
        NutritionCalculator.targetsFor(profile.copyWith(ageYears: 17)),
        isNull,
      );
    });

    test('uses profile identity, activity and goal in the estimate', () {
      final male = NutritionCalculator.targetsFor(profile)!;
      final female = NutritionCalculator.targetsFor(
        profile.copyWith(gender: RatGender.female),
      )!;
      final nonBinary = NutritionCalculator.targetsFor(
        profile.copyWith(gender: RatGender.nonBinary),
      )!;
      final fatLoss = NutritionCalculator.targetsFor(
        profile.copyWith(goal: TrainingGoal.fatLoss),
      )!;

      expect(male.calories, greaterThan(nonBinary.calories));
      expect(nonBinary.calories, greaterThan(female.calories));
      expect(fatLoss.calories, lessThan(male.calories));
    });

    test('returns internally consistent adult macro targets', () {
      final target = NutritionCalculator.targetsFor(profile)!;
      final macroCalories =
          target.proteinGrams * 4 +
          target.carbohydrateGrams * 4 +
          target.fatGrams * 9;
      final proteinShare = target.proteinGrams * 4 / target.calories;
      final carbohydrateShare = target.carbohydrateGrams * 4 / target.calories;
      final fatShare = target.fatGrams * 9 / target.calories;

      expect((macroCalories - target.calories).abs(), lessThanOrEqualTo(5));
      expect(proteinShare, inInclusiveRange(.10, .30));
      expect(carbohydrateShare, inInclusiveRange(.45, .65));
      expect(fatShare, inInclusiveRange(.24, .26));
    });
  });

  test('five-meal plan preserves the personalized daily target', () {
    final target = NutritionCalculator.targetsFor(profile)!;
    final plan = NutritionMealPlanner.planFor(target);

    expect(plan, hasLength(5));
    expect(plan.map((meal) => meal.titleKey), <String>[
      'mealBreakfast',
      'mealSnackOne',
      'mealLunch',
      'mealSnackTwo',
      'mealDinner',
    ]);
    expect(
      plan.fold<int>(0, (sum, meal) => sum + meal.calories),
      closeTo(target.calories, 2),
    );
    expect(
      plan.fold<int>(0, (sum, meal) => sum + meal.proteinGrams),
      closeTo(target.proteinGrams, 2),
    );
  });

  test('nutrition history supports day, week, month and year windows', () {
    final now = DateTime(2026, 9, 7, 12);
    final entries = [
      _nutritionEntry('today', DateTime(2026, 9, 7, 8), 500),
      _nutritionEntry('week', DateTime(2026, 9, 3, 12), 700),
      _nutritionEntry('month', DateTime(2026, 9, 1, 12), 900),
      _nutritionEntry('year', DateTime(2026, 2, 1, 12), 1100),
      _nutritionEntry('old', DateTime(2025, 12, 31, 12), 1300),
    ];

    expect(
      NutritionHistory.entriesFor(
        entries: entries,
        period: NutritionHistoryPeriod.day,
        now: now,
      ).map((entry) => entry.id),
      ['today'],
    );
    expect(
      NutritionHistory.entriesFor(
        entries: entries,
        period: NutritionHistoryPeriod.week,
        now: now,
      ).map((entry) => entry.id),
      ['today', 'week', 'month'],
    );
    expect(
      NutritionHistory.entriesFor(
        entries: entries,
        period: NutritionHistoryPeriod.month,
        now: now,
      ),
      hasLength(3),
    );
    expect(
      NutritionHistory.entriesFor(
        entries: entries,
        period: NutritionHistoryPeriod.year,
        now: now,
      ),
      hasLength(4),
    );
    expect(
      NutritionHistory.buckets(
        entries: entries,
        period: NutritionHistoryPeriod.year,
        now: now,
        dailyCalorieTarget: 2000,
      ),
      hasLength(12),
    );
  });

  group('NutritionStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('persists entries newest first and totals them', () async {
      await NutritionStore.add(
        name: 'Breakfast',
        calories: 450,
        proteinGrams: 30,
        carbohydrateGrams: 55,
        fatGrams: 12,
        loggedAt: DateTime(2026, 9, 5, 8),
      );
      await NutritionStore.add(
        name: 'Lunch',
        calories: 700,
        proteinGrams: 50,
        carbohydrateGrams: 80,
        fatGrams: 20,
        loggedAt: DateTime(2026, 9, 5, 12),
      );

      final entries = await NutritionStore.load();
      final totals = NutritionTotals.fromEntries(entries);

      expect(entries.map((entry) => entry.name), <String>[
        'Lunch',
        'Breakfast',
      ]);
      expect(totals.calories, 1150);
      expect(totals.proteinGrams, 80);
      expect(totals.carbohydrateGrams, 135);
      expect(totals.fatGrams, 32);
    });

    test('deletes one entry without touching the remainder', () async {
      final breakfast = await NutritionStore.add(
        name: 'Breakfast',
        calories: 450,
        proteinGrams: 30,
        carbohydrateGrams: 55,
        fatGrams: 12,
        loggedAt: DateTime(2026, 9, 5, 8),
      );
      await NutritionStore.add(
        name: 'Lunch',
        calories: 700,
        proteinGrams: 50,
        carbohydrateGrams: 80,
        fatGrams: 20,
        loggedAt: DateTime(2026, 9, 5, 12),
      );

      await NutritionStore.delete(breakfast.id);

      expect((await NutritionStore.load()).single.name, 'Lunch');
    });

    test('ignores corrupt and incomplete persisted entries', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'gymrat-nutrition-entries-v1': jsonEncode(<Object>[
          'broken',
          <String, Object>{'id': 'missing-fields'},
        ]),
      });

      expect(await NutritionStore.load(), isEmpty);
    });
  });
}

NutritionEntry _nutritionEntry(String id, DateTime loggedAt, int calories) =>
    NutritionEntry(
      id: id,
      name: id,
      loggedAt: loggedAt,
      calories: calories,
      proteinGrams: 20,
      carbohydrateGrams: 30,
      fatGrams: 10,
    );
