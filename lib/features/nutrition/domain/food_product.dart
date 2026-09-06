class FoodProduct {
  const FoodProduct({
    required this.barcode,
    required this.name,
    required this.caloriesPer100Grams,
    required this.proteinPer100Grams,
    required this.carbohydratesPer100Grams,
    required this.fatPer100Grams,
    this.brand,
    this.servingGrams,
    this.imageUrl,
  });

  final String barcode;
  final String name;
  final String? brand;
  final double caloriesPer100Grams;
  final double proteinPer100Grams;
  final double carbohydratesPer100Grams;
  final double fatPer100Grams;
  final double? servingGrams;
  final String? imageUrl;

  FoodProductNutrition nutritionForGrams(double grams) {
    final multiplier = grams.clamp(0, 5000) / 100;
    return FoodProductNutrition(
      calories: (caloriesPer100Grams * multiplier).round(),
      proteinGrams: proteinPer100Grams * multiplier,
      carbohydrateGrams: carbohydratesPer100Grams * multiplier,
      fatGrams: fatPer100Grams * multiplier,
    );
  }
}

class FoodProductNutrition {
  const FoodProductNutrition({
    required this.calories,
    required this.proteinGrams,
    required this.carbohydrateGrams,
    required this.fatGrams,
  });

  final int calories;
  final double proteinGrams;
  final double carbohydrateGrams;
  final double fatGrams;
}
