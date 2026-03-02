/// Модель рецепта, сгенерированного AI
class AiRecipe {
  final String title;
  final int timeMin;
  final int servings;
  final List<String> ingredients;
  final List<String> steps;
  final String? tip;

  const AiRecipe({
    required this.title,
    required this.timeMin,
    required this.servings,
    required this.ingredients,
    required this.steps,
    this.tip,
  });

  factory AiRecipe.fromJson(Map<String, dynamic> json) {
    return AiRecipe(
      title: json['title'] as String? ?? 'Рецепт',
      timeMin: (json['timeMin'] as num?)?.toInt() ?? 30,
      servings: (json['servings'] as num?)?.toInt() ?? 2,
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      steps:
          (json['steps'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
      tip: json['tip'] as String?,
    );
  }
}
