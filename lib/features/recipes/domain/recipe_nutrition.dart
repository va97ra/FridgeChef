class NutritionReferenceEntry {
  final String canonicalName;
  final List<String> aliases;
  final double baseAmount;
  final NutritionPerAmount nutrition;
  final String baseUnitKey;

  const NutritionReferenceEntry({
    required this.canonicalName,
    this.aliases = const [],
    required this.baseAmount,
    required this.nutrition,
    required this.baseUnitKey,
  });

  factory NutritionReferenceEntry.fromJson(Map<String, dynamic> json) {
    return NutritionReferenceEntry(
      canonicalName: (json['canonicalName'] as String? ?? '').trim(),
      aliases: (json['aliases'] as List<dynamic>? ?? const [])
          .map((value) => '$value')
          .toList(),
      baseAmount: (json['baseAmount'] as num?)?.toDouble() ?? 100,
      nutrition: NutritionPerAmount.fromJson(json),
      baseUnitKey: (json['baseUnit'] as String? ?? 'g').trim(),
    );
  }
}

class NutritionPerAmount {
  final double calories;
  final double protein;
  final double fat;
  final double carbs;

  const NutritionPerAmount({
    this.calories = 0,
    this.protein = 0,
    this.fat = 0,
    this.carbs = 0,
  });

  const NutritionPerAmount.zero()
      : calories = 0,
        protein = 0,
        fat = 0,
        carbs = 0;

  factory NutritionPerAmount.fromJson(Map<String, dynamic> json) {
    return NutritionPerAmount(
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
    );
  }

  NutritionPerAmount operator +(NutritionPerAmount other) {
    return NutritionPerAmount(
      calories: calories + other.calories,
      protein: protein + other.protein,
      fat: fat + other.fat,
      carbs: carbs + other.carbs,
    );
  }

  NutritionPerAmount scale(double factor) {
    return NutritionPerAmount(
      calories: calories * factor,
      protein: protein * factor,
      fat: fat * factor,
      carbs: carbs * factor,
    );
  }
}

class RecipeNutritionEstimate {
  final NutritionPerAmount total;
  final int matchedIngredients;
  final int totalIngredients;
  final List<String> missingIngredients;

  const RecipeNutritionEstimate({
    required this.total,
    required this.matchedIngredients,
    required this.totalIngredients,
    this.missingIngredients = const [],
  });

  bool get hasData => matchedIngredients > 0;

  double get coverage =>
      totalIngredients == 0 ? 0 : matchedIngredients / totalIngredients;

  RecipeNutritionEstimate scale(double factor) {
    return RecipeNutritionEstimate(
      total: total.scale(factor),
      matchedIngredients: matchedIngredients,
      totalIngredients: totalIngredients,
      missingIngredients: missingIngredients,
    );
  }
}
