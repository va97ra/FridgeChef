import 'recipe.dart';
import 'recipe_ingredient.dart';

enum RecipeMatchSource { base, generated }

extension RecipeMatchSourceX on RecipeMatchSource {
  String get label =>
      this == RecipeMatchSource.generated ? 'Шеф-идея' : 'База';
}

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
  final RecipeMatchSource source;
  final double score;
  final double coverageScore;
  final double pairingScore;
  final double priorityUsageScore;
  final double completenessScore;
  final double seasoningScore;
  final double techniqueScore;
  final double effortFitScore;
  final double personalScore;
  final double flavorScore;
  final List<String> why;
  final List<MissingIngredient> missingIngredients;
  final int matchedCount;
  final int totalCount;
  final int matchedRequired;
  final int totalRequired;
  final int matchedOptional;
  final int totalOptional;

  const RecipeMatch({
    required this.recipe,
    this.source = RecipeMatchSource.base,
    required this.score,
    this.coverageScore = 0,
    this.pairingScore = 0,
    this.priorityUsageScore = 0,
    this.completenessScore = 0,
    this.seasoningScore = 0,
    this.techniqueScore = 0,
    this.effortFitScore = 0,
    this.personalScore = 0.5,
    this.flavorScore = 0,
    this.why = const [],
    required this.missingIngredients,
    required this.matchedCount,
    required this.totalCount,
    required this.matchedRequired,
    required this.totalRequired,
    required this.matchedOptional,
    required this.totalOptional,
  });
}
