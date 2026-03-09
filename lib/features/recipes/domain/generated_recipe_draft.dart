class GeneratedRecipeDraft {
  final String title;
  final int timeMin;
  final int servings;
  final List<String> ingredients;
  final List<String> steps;
  final String? tip;

  const GeneratedRecipeDraft({
    required this.title,
    required this.timeMin,
    required this.servings,
    required this.ingredients,
    required this.steps,
    this.tip,
  });

  factory GeneratedRecipeDraft.fromJson(Map<String, dynamic> json) {
    return GeneratedRecipeDraft(
      title: json['title'] as String? ?? 'Рецепт',
      timeMin: (json['timeMin'] as num?)?.toInt() ?? 30,
      servings: (json['servings'] as num?)?.toInt() ?? 2,
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      steps:
          (json['steps'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      tip: json['tip'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'timeMin': timeMin,
      'servings': servings,
      'ingredients': ingredients,
      'steps': steps,
      'tip': tip,
    };
  }
}
