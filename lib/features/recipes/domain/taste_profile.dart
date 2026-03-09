import '../../fridge/domain/product_catalog_entry.dart';
import 'recipe.dart';
import 'recipe_ingredient_canonicalizer.dart';

enum RecipeFeedbackVote { disliked, liked }

extension RecipeFeedbackVoteX on RecipeFeedbackVote {
  String get storageValue {
    switch (this) {
      case RecipeFeedbackVote.disliked:
        return 'disliked';
      case RecipeFeedbackVote.liked:
        return 'liked';
    }
  }

  static RecipeFeedbackVote? fromStorage(String? raw) {
    switch (raw) {
      case 'disliked':
        return RecipeFeedbackVote.disliked;
      case 'liked':
        return RecipeFeedbackVote.liked;
      default:
        return null;
    }
  }
}

class TasteProfile {
  final Map<String, double> ingredientWeights;
  final Map<String, double> tagWeights;
  final Map<String, RecipeFeedbackVote> recipeVotes;

  const TasteProfile({
    this.ingredientWeights = const {},
    this.tagWeights = const {},
    this.recipeVotes = const {},
  });

  const TasteProfile.empty() : this();

  TasteProfileAnalysis analyzeRecipe({
    required Recipe recipe,
    required RecipeIngredientCanonicalizer canonicalizer,
  }) {
    final directVote = recipeVotes[recipe.id];
    if (directVote == RecipeFeedbackVote.liked) {
      return const TasteProfileAnalysis(
        score: 1.0,
        reasons: ['ты уже отмечал этот рецепт как удачный'],
      );
    }
    if (directVote == RecipeFeedbackVote.disliked) {
      return const TasteProfileAnalysis(
        score: 0.0,
        warnings: ['этот рецепт тебе уже не понравился'],
      );
    }

    final ingredientScores = <double>[];
    for (final ingredient in recipe.ingredients) {
      final canonical = canonicalizer.canonicalize(ingredient.name);
      final value = ingredientWeights[canonical];
      if (value != null) {
        ingredientScores.add(value);
      }
    }

    final tagScores = <double>[];
    for (final tag in recipe.tags) {
      final normalized = tag.trim().toLowerCase();
      final value = tagWeights[normalized];
      if (value != null) {
        tagScores.add(value);
      }
    }

    final ingredientAvg = ingredientScores.isEmpty
        ? 0.0
        : ingredientScores.reduce((a, b) => a + b) / ingredientScores.length;
    final tagAvg =
        tagScores.isEmpty ? 0.0 : tagScores.reduce((a, b) => a + b) / tagScores.length;

    final reasons = <String>[];
    final warnings = <String>[];
    if (ingredientAvg >= 0.16) {
      reasons.add('похоже на блюда, которые тебе обычно нравятся');
    } else if (ingredientAvg <= -0.16) {
      warnings.add('похоже на сочетания, которые тебе раньше не зашли');
    }
    if (tagAvg >= 0.16) {
      reasons.add('совпадает с твоими привычными форматами блюд');
    } else if (tagAvg <= -0.16) {
      warnings.add('формат блюда не похож на твои удачные выборы');
    }

    final score = (0.5 + (ingredientAvg * 0.32) + (tagAvg * 0.18))
        .clamp(0.0, 1.0);

    return TasteProfileAnalysis(
      score: score,
      reasons: reasons,
      warnings: warnings,
    );
  }
}

class TasteProfileAnalysis {
  final double score;
  final List<String> reasons;
  final List<String> warnings;

  const TasteProfileAnalysis({
    required this.score,
    this.reasons = const [],
    this.warnings = const [],
  });
}

TasteProfile buildTasteProfile({
  required Map<String, RecipeFeedbackVote> feedbackByRecipeId,
  required List<Recipe> recipes,
  required List<ProductCatalogEntry> catalog,
}) {
  if (feedbackByRecipeId.isEmpty || recipes.isEmpty || catalog.isEmpty) {
    return TasteProfile(recipeVotes: feedbackByRecipeId);
  }

  final canonicalizer = RecipeIngredientCanonicalizer(catalog);
  final ingredientSums = <String, double>{};
  final ingredientCounts = <String, int>{};
  final tagSums = <String, double>{};
  final tagCounts = <String, int>{};
  final recipeById = {
    for (final recipe in recipes) recipe.id: recipe,
  };

  for (final entry in feedbackByRecipeId.entries) {
    final recipe = recipeById[entry.key];
    if (recipe == null) {
      continue;
    }

    final weight = entry.value == RecipeFeedbackVote.liked ? 1.0 : -1.0;
    for (final ingredient in recipe.ingredients) {
      final canonical = canonicalizer.canonicalize(ingredient.name);
      if (canonical.isEmpty) {
        continue;
      }
      ingredientSums[canonical] = (ingredientSums[canonical] ?? 0.0) + weight;
      ingredientCounts[canonical] = (ingredientCounts[canonical] ?? 0) + 1;
    }

    for (final tag in recipe.tags) {
      final normalized = tag.trim().toLowerCase();
      if (normalized.isEmpty) {
        continue;
      }
      tagSums[normalized] = (tagSums[normalized] ?? 0.0) + (weight * 0.8);
      tagCounts[normalized] = (tagCounts[normalized] ?? 0) + 1;
    }
  }

  return TasteProfile(
    ingredientWeights: {
      for (final key in ingredientSums.keys)
        key: (ingredientSums[key]! / ingredientCounts[key]!).clamp(-1.0, 1.0),
    },
    tagWeights: {
      for (final key in tagSums.keys)
        key: (tagSums[key]! / tagCounts[key]!).clamp(-1.0, 1.0),
    },
    recipeVotes: feedbackByRecipeId,
  );
}
