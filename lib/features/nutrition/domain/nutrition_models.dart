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
