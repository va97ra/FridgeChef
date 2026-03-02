import 'recipe.dart';
import 'recipe_ingredient.dart';

class MissingIngredient {
  final RecipeIngredient ingredient;
  final double missingAmount;

  const MissingIngredient({
    required this.ingredient,
    required this.missingAmount,
  });
}

class RecipeMatch {
  final Recipe recipe;
  final double score;
  final List<MissingIngredient> missingIngredients;
  final int matchedCount;
  final int totalCount;
  final int matchedRequired;
  final int totalRequired;
  final int matchedOptional;
  final int totalOptional;

  const RecipeMatch({
    required this.recipe,
    required this.score,
    required this.missingIngredients,
    required this.matchedCount,
    required this.totalCount,
    required this.matchedRequired,
    required this.totalRequired,
    required this.matchedOptional,
    required this.totalOptional,
  });
}
