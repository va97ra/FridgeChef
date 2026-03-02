import '../../../core/utils/units.dart';

class RecipeIngredient {
  final String name;
  final double amount;
  final Unit unit;
  final bool required;

  const RecipeIngredient({
    required this.name,
    required this.amount,
    required this.unit,
    this.required = true,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      unit: Unit.values
          .firstWhere((e) => e.name == json['unit'], orElse: () => Unit.pcs),
      required: json['required'] as bool? ?? true,
    );
  }
}

class Recipe {
  final String id;
  final String title;
  final int timeMin;
  final List<String> tags;
  final int servingsBase;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;

  const Recipe({
    required this.id,
    required this.title,
    required this.timeMin,
    required this.tags,
    required this.servingsBase,
    required this.ingredients,
    required this.steps,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      title: json['title'] as String,
      timeMin: json['timeMin'] as int,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
      servingsBase: json['servingsBase'] as int,
      ingredients: (json['ingredients'] as List<dynamic>)
          .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      steps: (json['steps'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }
}
