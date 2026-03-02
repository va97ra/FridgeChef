import 'recipe.dart';

class RecipeMatch {
  final Recipe recipe;
  final double score;
  final List<RecipeIngredient> missingIngredients;
  final int matchedCount;
  final int totalCount;

  const RecipeMatch({
    required this.recipe,
    required this.score,
    required this.missingIngredients,
    required this.matchedCount,
    required this.totalCount,
  });
}
