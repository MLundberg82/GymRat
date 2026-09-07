import '../../profile/domain/training_profile.dart';

class NutritionEntry {
  const NutritionEntry({
    required this.id,
    required this.name,
    required this.loggedAt,
    required this.calories,
    required this.proteinGrams,
    required this.carbohydrateGrams,
    required this.fatGrams,
  });

  final String id;
  final String name;
  final DateTime loggedAt;
  final int calories;
  final double proteinGrams;
  final double carbohydrateGrams;
  final double fatGrams;

  Map<String, Object> toJson() => <String, Object>{
    'id': id,
    'name': name,
    'loggedAt': loggedAt.toIso8601String(),
    'calories': calories,
    'proteinGrams': proteinGrams,
    'carbohydrateGrams': carbohydrateGrams,
    'fatGrams': fatGrams,
  };

  static NutritionEntry? tryParse(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final loggedAt = DateTime.tryParse(json['loggedAt'] as String? ?? '');
    final calories = json['calories'];
    final protein = json['proteinGrams'];
    final carbohydrates = json['carbohydrateGrams'];
    final fat = json['fatGrams'];
    if (id is! String ||
        name is! String ||
        name.trim().isEmpty ||
        loggedAt == null ||
        calories is! num ||
        protein is! num ||
        carbohydrates is! num ||
        fat is! num) {
      return null;
    }
    return NutritionEntry(
      id: id,
      name: name.trim(),
      loggedAt: loggedAt,
      calories: calories.toInt().clamp(0, 10000),
      proteinGrams: protein.toDouble().clamp(0, 1000),
      carbohydrateGrams: carbohydrates.toDouble().clamp(0, 2000),
      fatGrams: fat.toDouble().clamp(0, 1000),
    );
  }
}

class NutritionTotals {
  const NutritionTotals({
    this.calories = 0,
    this.proteinGrams = 0,
    this.carbohydrateGrams = 0,
    this.fatGrams = 0,
  });

  final int calories;
  final double proteinGrams;
  final double carbohydrateGrams;
  final double fatGrams;

  factory NutritionTotals.fromEntries(Iterable<NutritionEntry> entries) {
    var calories = 0;
    var protein = 0.0;
    var carbohydrates = 0.0;
    var fat = 0.0;
    for (final entry in entries) {
      calories += entry.calories;
      protein += entry.proteinGrams;
      carbohydrates += entry.carbohydrateGrams;
      fat += entry.fatGrams;
    }
    return NutritionTotals(
      calories: calories,
      proteinGrams: protein,
      carbohydrateGrams: carbohydrates,
      fatGrams: fat,
    );
  }
}

enum NutritionHistoryPeriod { day, week, month, year }

class NutritionHistoryBucket {
  const NutritionHistoryBucket({
    required this.label,
    required this.start,
    required this.end,
    required this.targetCalories,
    required this.totals,
  });

  final String label;
  final DateTime start;
  final DateTime end;
  final int targetCalories;
  final NutritionTotals totals;
}

abstract final class NutritionHistory {
  static List<NutritionHistoryBucket> buckets({
    required Iterable<NutritionEntry> entries,
    required NutritionHistoryPeriod period,
    required DateTime now,
    required int dailyCalorieTarget,
  }) {
    final localNow = now.toLocal();
    final today = DateTime(localNow.year, localNow.month, localNow.day);
    return switch (period) {
      NutritionHistoryPeriod.day => List.generate(6, (index) {
        final start = today.add(Duration(hours: index * 4));
        final end = start.add(const Duration(hours: 4));
        return _bucket(
          entries,
          label: '${index * 4}'.padLeft(2, '0'),
          start: start,
          end: end,
          targetCalories: (dailyCalorieTarget / 6).round(),
        );
      }),
      NutritionHistoryPeriod.week => List.generate(7, (index) {
        final start = today.subtract(Duration(days: 6 - index));
        return _bucket(
          entries,
          label: '${start.day}',
          start: start,
          end: start.add(const Duration(days: 1)),
          targetCalories: dailyCalorieTarget,
        );
      }),
      NutritionHistoryPeriod.month => _monthBuckets(
        entries,
        today: today,
        dailyCalorieTarget: dailyCalorieTarget,
      ),
      NutritionHistoryPeriod.year => List.generate(12, (index) {
        final start = DateTime(today.year, index + 1);
        final end = DateTime(today.year, index + 2);
        return _bucket(
          entries,
          label: '${index + 1}',
          start: start,
          end: end,
          targetCalories: dailyCalorieTarget * end.difference(start).inDays,
        );
      }),
    };
  }

  static List<NutritionEntry> entriesFor({
    required Iterable<NutritionEntry> entries,
    required NutritionHistoryPeriod period,
    required DateTime now,
  }) {
    final localNow = now.toLocal();
    final today = DateTime(localNow.year, localNow.month, localNow.day);
    final start = switch (period) {
      NutritionHistoryPeriod.day => today,
      NutritionHistoryPeriod.week => today.subtract(const Duration(days: 6)),
      NutritionHistoryPeriod.month => DateTime(today.year, today.month),
      NutritionHistoryPeriod.year => DateTime(today.year),
    };
    final end = switch (period) {
      NutritionHistoryPeriod.day => today.add(const Duration(days: 1)),
      NutritionHistoryPeriod.week => today.add(const Duration(days: 1)),
      NutritionHistoryPeriod.month => DateTime(today.year, today.month + 1),
      NutritionHistoryPeriod.year => DateTime(today.year + 1),
    };
    return entries
        .where(
          (entry) =>
              !entry.loggedAt.isBefore(start) && entry.loggedAt.isBefore(end),
        )
        .toList(growable: false);
  }

  static List<NutritionHistoryBucket> _monthBuckets(
    Iterable<NutritionEntry> entries, {
    required DateTime today,
    required int dailyCalorieTarget,
  }) {
    final monthStart = DateTime(today.year, today.month);
    final monthEnd = DateTime(today.year, today.month + 1);
    final result = <NutritionHistoryBucket>[];
    var cursor = monthStart;
    var index = 1;
    while (cursor.isBefore(monthEnd)) {
      final candidateEnd = cursor.add(const Duration(days: 7));
      final end = candidateEnd.isAfter(monthEnd) ? monthEnd : candidateEnd;
      result.add(
        _bucket(
          entries,
          label: 'W$index',
          start: cursor,
          end: end,
          targetCalories: dailyCalorieTarget * end.difference(cursor).inDays,
        ),
      );
      cursor = end;
      index += 1;
    }
    return result;
  }

  static NutritionHistoryBucket _bucket(
    Iterable<NutritionEntry> entries, {
    required String label,
    required DateTime start,
    required DateTime end,
    required int targetCalories,
  }) => NutritionHistoryBucket(
    label: label,
    start: start,
    end: end,
    targetCalories: targetCalories,
    totals: NutritionTotals.fromEntries(
      entries.where(
        (entry) =>
            !entry.loggedAt.isBefore(start) && entry.loggedAt.isBefore(end),
      ),
    ),
  );
}

class NutritionTargets {
  const NutritionTargets({
    required this.calories,
    required this.proteinGrams,
    required this.carbohydrateGrams,
    required this.fatGrams,
  });

  final int calories;
  final int proteinGrams;
  final int carbohydrateGrams;
  final int fatGrams;
}

class MealPlanSuggestion {
  const MealPlanSuggestion({
    required this.titleKey,
    required this.descriptionKey,
    required this.calories,
    required this.proteinGrams,
    required this.carbohydrateGrams,
    required this.fatGrams,
  });

  final String titleKey;
  final String descriptionKey;
  final int calories;
  final int proteinGrams;
  final int carbohydrateGrams;
  final int fatGrams;
}

abstract final class NutritionMealPlanner {
  static const _slots = <(String, String, double)>[
    ('mealBreakfast', 'mealBreakfastExample', .22),
    ('mealSnackOne', 'mealSnackOneExample', .10),
    ('mealLunch', 'mealLunchExample', .28),
    ('mealSnackTwo', 'mealSnackTwoExample', .10),
    ('mealDinner', 'mealDinnerExample', .30),
  ];

  static List<MealPlanSuggestion> planFor(NutritionTargets targets) => _slots
      .map(
        (slot) => MealPlanSuggestion(
          titleKey: slot.$1,
          descriptionKey: slot.$2,
          calories: (targets.calories * slot.$3).round(),
          proteinGrams: (targets.proteinGrams * slot.$3).round(),
          carbohydrateGrams: (targets.carbohydrateGrams * slot.$3).round(),
          fatGrams: (targets.fatGrams * slot.$3).round(),
        ),
      )
      .toList(growable: false);
}

abstract final class NutritionCalculator {
  static NutritionTargets? targetsFor(TrainingProfile profile) {
    final age = profile.ageYears;
    if (age == null || age < 18) return null;

    final genderAdjustment = switch (profile.gender) {
      RatGender.male => 5.0,
      RatGender.female => -161.0,
      RatGender.nonBinary => -78.0,
    };
    final basalMetabolicRate =
        10 * profile.weightKg +
        6.25 * profile.heightCm -
        5 * age +
        genderAdjustment;
    final activityMultiplier = switch (profile.sessionsPerWeek) {
      <= 2 => 1.35,
      <= 4 => 1.50,
      <= 6 => 1.65,
      _ => 1.75,
    };
    final goalAdjustment = switch (profile.goal) {
      TrainingGoal.buildMuscle => 250,
      TrainingGoal.strength => 150,
      TrainingGoal.fatLoss => -350,
      TrainingGoal.generalFitness => 0,
    };
    final calories = (basalMetabolicRate * activityMultiplier + goalAdjustment)
        .round()
        .clamp(1400, 4500);
    final proteinPerKilogram = switch (profile.goal) {
      TrainingGoal.buildMuscle => 2.0,
      TrainingGoal.strength => 1.8,
      TrainingGoal.fatLoss => 2.0,
      TrainingGoal.generalFitness => 1.6,
    };
    // Keep the complete macro recommendation internally consistent and inside
    // the adult AMDR: protein 10–30%, fat 25%, carbohydrates 45–65%.
    final minimumProtein = (calories * .10 / 4).ceil();
    final maximumProtein = (calories * .30 / 4).floor();
    final protein = (profile.weightKg * proteinPerKilogram).round().clamp(
      minimumProtein,
      maximumProtein,
    );
    final fat = (calories * .25 / 9).round();
    final carbohydrates = ((calories - protein * 4 - fat * 9) / 4).round();
    return NutritionTargets(
      calories: calories,
      proteinGrams: protein,
      carbohydrateGrams: carbohydrates,
      fatGrams: fat,
    );
  }

  static bool sameDay(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}
