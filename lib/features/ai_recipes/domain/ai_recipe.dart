import '../../recipes/domain/generated_recipe_draft.dart';

/// Legacy compatibility wrapper.
class AiRecipe extends GeneratedRecipeDraft {
  const AiRecipe({
    required super.title,
    required super.timeMin,
    required super.servings,
    required super.ingredients,
    required super.steps,
    super.tip,
  });

  factory AiRecipe.fromJson(Map<String, dynamic> json) {
    final draft = GeneratedRecipeDraft.fromJson(json);
    return AiRecipe(
      title: draft.title,
      timeMin: draft.timeMin,
      servings: draft.servings,
      ingredients: draft.ingredients,
      steps: draft.steps,
      tip: draft.tip,
    );
  }
}
