import 'dart:math' as math;

import '../../fridge/domain/product_catalog_entry.dart';
import 'chef_rules.dart';
import 'ingredient_knowledge.dart';
import 'recipe.dart';
import 'recipe_ingredient_canonicalizer.dart';
import 'recipe_interaction_event.dart';

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
  final Map<String, double> pairWeights;
  final Map<String, double> profileWeights;
  final Map<String, double> techniqueWeights;
  final Map<String, double> ingredientFatigueWeights;
  final Map<String, double> profileFatigueWeights;
  final Map<String, double> recipeFatigueWeights;
  final Map<String, RecipeFeedbackVote> recipeVotes;

  const TasteProfile({
    this.ingredientWeights = const {},
    this.tagWeights = const {},
    this.pairWeights = const {},
    this.profileWeights = const {},
    this.techniqueWeights = const {},
    this.ingredientFatigueWeights = const {},
    this.profileFatigueWeights = const {},
    this.recipeFatigueWeights = const {},
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

    final canonicals = _recipeCanonicals(
      recipe: recipe,
      canonicalizer: canonicalizer,
    );
    final ingredientScores = <double>[];
    for (final canonical in canonicals) {
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

    final pairScores = <double>[];
    final pairKeys = _pairKeysForCanonicals(canonicals);
    for (final key in pairKeys) {
      final value = pairWeights[key];
      if (value != null) {
        pairScores.add(value);
      }
    }

    final profile = inferDishProfile(
      title: recipe.title,
      tags: recipe.tags,
      ingredientCanonicals: canonicals,
    );
    final fatigue = recipeFatigue(
      recipe: recipe,
      canonicalizer: canonicalizer,
      canonicals: canonicals,
      profile: profile,
    );
    final profileScore = profileWeights[profile.name] ?? 0.0;
    final techniqueScores = <double>[];
    for (final signal
        in _extractTechniqueSignals(recipe: recipe, profile: profile)) {
      final value = techniqueWeights[signal];
      if (value != null) {
        techniqueScores.add(value);
      }
    }

    final ingredientAvg = ingredientScores.isEmpty
        ? 0.0
        : ingredientScores.reduce((a, b) => a + b) / ingredientScores.length;
    final tagAvg = tagScores.isEmpty
        ? 0.0
        : tagScores.reduce((a, b) => a + b) / tagScores.length;
    final pairAvg = pairScores.isEmpty
        ? 0.0
        : pairScores.reduce((a, b) => a + b) / pairScores.length;
    final techniqueAvg = techniqueScores.isEmpty
        ? 0.0
        : techniqueScores.reduce((a, b) => a + b) / techniqueScores.length;

    final reasons = <String>[];
    final warnings = <String>[];
    if (ingredientAvg >= 0.16) {
      reasons.add('похоже на блюда, которые тебе обычно нравятся');
    } else if (ingredientAvg <= -0.16) {
      warnings.add('похоже на сочетания, которые тебе раньше не зашли');
    }
    if (pairAvg >= 0.16) {
      reasons.add('внутри есть сочетания, которые у тебя часто заходят');
    } else if (pairAvg <= -0.16) {
      warnings.add(
          'внутри есть пары ингредиентов, которые тебе обычно не нравятся');
    }
    if (profileScore >= 0.16) {
      reasons.add('это похоже на тот тип блюда, который ты любишь');
    } else if (profileScore <= -0.16) {
      warnings.add('сам формат блюда не слишком похож на твои удачные выборы');
    }
    if (tagAvg >= 0.16) {
      reasons.add('совпадает с твоими привычными форматами блюд');
    } else if (tagAvg <= -0.16) {
      warnings.add('формат блюда не похож на твои удачные выборы');
    }
    if (techniqueAvg >= 0.14) {
      reasons.add('способ приготовления похож на то, что тебе уже нравилось');
    } else if (techniqueAvg <= -0.14) {
      warnings.add('манера приготовления не похожа на твои удачные рецепты');
    }
    if (fatigue >= 0.24) {
      warnings.add('такой формат у тебя уже был совсем недавно');
    }

    final score = (0.48 +
            (ingredientAvg * 0.22) +
            (pairAvg * 0.18) +
            (profileScore * 0.12) +
            (tagAvg * 0.08) +
            (techniqueAvg * 0.08) -
            (fatigue * 0.16))
        .clamp(0.0, 1.0);

    return TasteProfileAnalysis(
      score: score,
      reasons: reasons,
      warnings: warnings,
    );
  }

  double ingredientPreference(String canonical) {
    return ingredientWeights[normalizeIngredientText(canonical)] ?? 0.0;
  }

  double ingredientFatigue(String canonical) {
    return ingredientFatigueWeights[normalizeIngredientText(canonical)] ?? 0.0;
  }

  double pairPreference(String first, String second) {
    if (first.trim().isEmpty || second.trim().isEmpty) {
      return 0.0;
    }
    return pairWeights[_pairKey(first, second)] ?? 0.0;
  }

  double averagePairPreference(Iterable<String> canonicals) {
    final keys = _pairKeysForCanonicals(
      canonicals
          .map(normalizeIngredientText)
          .where((value) => value.isNotEmpty),
    );
    if (keys.isEmpty) {
      return 0.0;
    }
    var total = 0.0;
    for (final key in keys) {
      total += pairWeights[key] ?? 0.0;
    }
    return total / keys.length;
  }

  double profilePreference(DishProfile profile) {
    return profileWeights[profile.name] ?? 0.0;
  }

  double profileFatigue(DishProfile profile) {
    return profileFatigueWeights[profile.name] ?? 0.0;
  }

  double averageTagPreference(Iterable<String> tags) {
    final normalized =
        tags.map(_normalizeTag).where((value) => value.isNotEmpty).toList();
    if (normalized.isEmpty) {
      return 0.0;
    }
    var total = 0.0;
    for (final tag in normalized) {
      total += tagWeights[tag] ?? 0.0;
    }
    return total / normalized.length;
  }

  double averageTechniquePreference(Set<String> techniqueSignals) {
    if (techniqueSignals.isEmpty) {
      return 0.0;
    }
    var total = 0.0;
    for (final signal in techniqueSignals) {
      total += techniqueWeights[signal] ?? 0.0;
    }
    return total / techniqueSignals.length;
  }

  double averageIngredientFatigue(Iterable<String> canonicals) {
    final normalized = canonicals
        .map(normalizeIngredientText)
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    if (normalized.isEmpty) {
      return 0.0;
    }
    var total = 0.0;
    for (final canonical in normalized) {
      total += ingredientFatigueWeights[canonical] ?? 0.0;
    }
    return total / normalized.length;
  }

  double recipeFatigue({
    required Recipe recipe,
    required RecipeIngredientCanonicalizer canonicalizer,
    List<String>? canonicals,
    DishProfile? profile,
  }) {
    final resolvedCanonicals = canonicals ??
        _recipeCanonicals(
          recipe: recipe,
          canonicalizer: canonicalizer,
        );
    final resolvedProfile = profile ??
        inferDishProfile(
          title: recipe.title,
          tags: recipe.tags,
          ingredientCanonicals: resolvedCanonicals,
        );
    final fingerprint = _recipeMemoryFingerprint(
      recipe: recipe,
      canonicalizer: canonicalizer,
      canonicals: resolvedCanonicals,
      profile: resolvedProfile,
    );
    final exact = recipeFatigueWeights[fingerprint] ?? 0.0;
    final profilePenalty = profileFatigue(resolvedProfile);
    final ingredientPenalty = averageIngredientFatigue(resolvedCanonicals);
    return ((exact * 0.55) +
            (profilePenalty * 0.25) +
            (ingredientPenalty * 0.20))
        .clamp(0.0, 1.0);
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
  List<RecipeInteractionEvent> interactionHistory = const [],
  DateTime? referenceTime,
}) {
  if (catalog.isEmpty || (recipes.isEmpty && interactionHistory.isEmpty)) {
    return TasteProfile(recipeVotes: feedbackByRecipeId);
  }

  final memoryReferenceTime = referenceTime ?? DateTime.now();
  final canonicalizer = RecipeIngredientCanonicalizer(catalog);
  final ingredientSums = <String, double>{};
  final ingredientCounts = <String, int>{};
  final tagSums = <String, double>{};
  final tagCounts = <String, int>{};
  final pairSums = <String, double>{};
  final pairCounts = <String, int>{};
  final profileSums = <String, double>{};
  final profileCounts = <String, int>{};
  final techniqueSums = <String, double>{};
  final techniqueCounts = <String, int>{};
  final ingredientFatigueSums = <String, double>{};
  final profileFatigueSums = <String, double>{};
  final recipeFatigueSums = <String, double>{};
  final interactionFrequencyByFingerprint = _buildInteractionFrequencyMap(
    interactionHistory: interactionHistory,
    canonicalizer: canonicalizer,
  );
  for (final recipe in recipes) {
    final weight = _memoryWeightForRecipe(
      recipe: recipe,
      feedbackByRecipeId: feedbackByRecipeId,
      memoryReferenceTime: memoryReferenceTime,
    );
    if (weight.abs() < 0.01) {
      continue;
    }
    _accumulateRecipeMemory(
      recipe: recipe,
      canonicalizer: canonicalizer,
      weight: weight,
      ingredientSums: ingredientSums,
      ingredientCounts: ingredientCounts,
      tagSums: tagSums,
      tagCounts: tagCounts,
      pairSums: pairSums,
      pairCounts: pairCounts,
      profileSums: profileSums,
      profileCounts: profileCounts,
      techniqueSums: techniqueSums,
      techniqueCounts: techniqueCounts,
    );
  }

  for (final event in interactionHistory) {
    final canonicals = _recipeCanonicals(
      recipe: event.recipeSnapshot,
      canonicalizer: canonicalizer,
    );
    final profile = inferDishProfile(
      title: event.recipeSnapshot.title,
      tags: event.recipeSnapshot.tags,
      ingredientCanonicals: canonicals,
    );
    final fingerprint = _recipeMemoryFingerprint(
      recipe: event.recipeSnapshot,
      canonicalizer: canonicalizer,
      canonicals: canonicals,
      profile: profile,
    );
    final weight = _memoryWeightForInteraction(
      event: event,
      memoryReferenceTime: memoryReferenceTime,
      sameFamilyCount:
          interactionFrequencyByFingerprint[_interactionFingerprintKey(
                event.type,
                fingerprint,
              )] ??
              1,
    );
    final fatigueWeight = _fatigueWeightForInteraction(
      event: event,
      memoryReferenceTime: memoryReferenceTime,
      sameFamilyCount:
          interactionFrequencyByFingerprint[_interactionFingerprintKey(
                event.type,
                fingerprint,
              )] ??
              1,
    );
    if (weight.abs() < 0.01) {
      if (fatigueWeight <= 0.01) {
        continue;
      }
    }

    if (weight.abs() >= 0.01) {
      _accumulateRecipeMemory(
        recipe: event.recipeSnapshot,
        canonicalizer: canonicalizer,
        weight: weight,
        ingredientSums: ingredientSums,
        ingredientCounts: ingredientCounts,
        tagSums: tagSums,
        tagCounts: tagCounts,
        pairSums: pairSums,
        pairCounts: pairCounts,
        profileSums: profileSums,
        profileCounts: profileCounts,
        techniqueSums: techniqueSums,
        techniqueCounts: techniqueCounts,
      );
    }
    if (fatigueWeight > 0.01) {
      _accumulateRecentFatigue(
        canonicals: canonicals,
        profile: profile,
        fingerprint: fingerprint,
        fatigueWeight: fatigueWeight,
        ingredientFatigueSums: ingredientFatigueSums,
        profileFatigueSums: profileFatigueSums,
        recipeFatigueSums: recipeFatigueSums,
      );
    }
  }

  return TasteProfile(
    ingredientWeights: {
      for (final key in ingredientSums.keys)
        key: _resolveMemorySignal(
          sum: ingredientSums[key]!,
          count: ingredientCounts[key]!,
        ),
    },
    tagWeights: {
      for (final key in tagSums.keys)
        key: _resolveMemorySignal(
          sum: tagSums[key]!,
          count: tagCounts[key]!,
        ),
    },
    pairWeights: {
      for (final key in pairSums.keys)
        key: _resolveMemorySignal(
          sum: pairSums[key]!,
          count: pairCounts[key]!,
        ),
    },
    profileWeights: {
      for (final key in profileSums.keys)
        key: _resolveMemorySignal(
          sum: profileSums[key]!,
          count: profileCounts[key]!,
        ),
    },
    techniqueWeights: {
      for (final key in techniqueSums.keys)
        key: _resolveMemorySignal(
          sum: techniqueSums[key]!,
          count: techniqueCounts[key]!,
        ),
    },
    ingredientFatigueWeights: {
      for (final key in ingredientFatigueSums.keys)
        key: _resolveFatigueSignal(ingredientFatigueSums[key]!, curve: 0.78),
    },
    profileFatigueWeights: {
      for (final key in profileFatigueSums.keys)
        key: _resolveFatigueSignal(profileFatigueSums[key]!, curve: 0.92),
    },
    recipeFatigueWeights: {
      for (final key in recipeFatigueSums.keys)
        key: _resolveFatigueSignal(recipeFatigueSums[key]!, curve: 1.08),
    },
    recipeVotes: feedbackByRecipeId,
  );
}

double _memoryWeightForRecipe({
  required Recipe recipe,
  required Map<String, RecipeFeedbackVote> feedbackByRecipeId,
  required DateTime memoryReferenceTime,
}) {
  final explicit = feedbackByRecipeId[recipe.id];
  if (explicit == RecipeFeedbackVote.liked) {
    return 1.0;
  }
  if (explicit == RecipeFeedbackVote.disliked) {
    return -1.0;
  }

  var weight = 0.0;
  if (recipe.source == RecipeSource.generatedSaved) {
    weight += 0.55;
  }
  if (recipe.isUserEditable) {
    weight += 0.10;
  }

  final createdAt = recipe.createdAt;
  final updatedAt = recipe.updatedAt;
  if (createdAt != null && updatedAt != null) {
    final minutes = updatedAt.difference(createdAt).inMinutes.abs();
    if (minutes >= 5) {
      weight += 0.12;
    }
  }

  final recipeReferenceTime = updatedAt ?? createdAt;
  if (recipeReferenceTime != null) {
    final ageDays = memoryReferenceTime.difference(recipeReferenceTime).inDays;
    weight = (weight *
            _ageDecayFactor(
              ageDays: ageDays,
              halfLifeDays: 75,
              minimumFactor: 0.26,
            )) +
        _freshnessBonus(ageDays);
  }

  return weight.clamp(0.0, 0.8);
}

double _memoryWeightForInteraction({
  required RecipeInteractionEvent event,
  required DateTime memoryReferenceTime,
  required int sameFamilyCount,
}) {
  final ageDays = memoryReferenceTime.difference(event.occurredAt).inDays;
  final baseWeight = switch (event.type) {
    RecipeInteractionType.saved => 0.72,
    RecipeInteractionType.renamed => 0.24,
    RecipeInteractionType.deleted => -0.78,
    RecipeInteractionType.recooked => 0.95,
    RecipeInteractionType.ignored => -0.24,
  };
  final frequencyFactor = _interactionFrequencyFactor(
    type: event.type,
    sameFamilyCount: sameFamilyCount,
  );
  final recencyFactor = _ageDecayFactor(
    ageDays: ageDays,
    halfLifeDays: event.type == RecipeInteractionType.recooked ? 48 : 62,
    minimumFactor: event.type == RecipeInteractionType.ignored ? 0.18 : 0.22,
  );

  return (baseWeight * frequencyFactor * recencyFactor).clamp(-1.0, 1.0);
}

double _fatigueWeightForInteraction({
  required RecipeInteractionEvent event,
  required DateTime memoryReferenceTime,
  required int sameFamilyCount,
}) {
  final baseWeight = switch (event.type) {
    RecipeInteractionType.saved => 0.18,
    RecipeInteractionType.renamed => 0.05,
    RecipeInteractionType.deleted => 0.62,
    RecipeInteractionType.recooked => 0.55,
    RecipeInteractionType.ignored => 0.82,
  };
  final ageDays = memoryReferenceTime.difference(event.occurredAt).inDays;
  final decay = _ageDecayFactor(
    ageDays: ageDays,
    halfLifeDays: switch (event.type) {
      RecipeInteractionType.saved => 9,
      RecipeInteractionType.renamed => 6,
      RecipeInteractionType.deleted => 16,
      RecipeInteractionType.recooked => 7,
      RecipeInteractionType.ignored => 11,
    },
    minimumFactor: 0.0,
  );
  final frequencyBoost = 1.0 +
      (math.log(sameFamilyCount.toDouble()) *
              switch (event.type) {
                RecipeInteractionType.saved => 0.08,
                RecipeInteractionType.renamed => 0.04,
                RecipeInteractionType.deleted => 0.14,
                RecipeInteractionType.recooked => 0.16,
                RecipeInteractionType.ignored => 0.18,
              })
          .clamp(
        0.0,
        switch (event.type) {
          RecipeInteractionType.saved => 0.18,
          RecipeInteractionType.renamed => 0.10,
          RecipeInteractionType.deleted => 0.30,
          RecipeInteractionType.recooked => 0.34,
          RecipeInteractionType.ignored => 0.36,
        },
      );
  return (baseWeight * decay * frequencyBoost).clamp(0.0, 1.0);
}

double _interactionFrequencyFactor({
  required RecipeInteractionType type,
  required int sameFamilyCount,
}) {
  if (sameFamilyCount <= 1) {
    return 1.0;
  }

  final rawBoost = math.log(sameFamilyCount.toDouble()) *
      switch (type) {
        RecipeInteractionType.recooked => 0.24,
        RecipeInteractionType.saved => 0.16,
        RecipeInteractionType.renamed => 0.08,
        RecipeInteractionType.deleted => 0.22,
        RecipeInteractionType.ignored => 0.26,
      };
  final maxBoost = switch (type) {
    RecipeInteractionType.recooked => 0.48,
    RecipeInteractionType.saved => 0.28,
    RecipeInteractionType.renamed => 0.14,
    RecipeInteractionType.deleted => 0.42,
    RecipeInteractionType.ignored => 0.50,
  };
  return 1.0 + rawBoost.clamp(0.0, maxBoost);
}

double _ageDecayFactor({
  required int ageDays,
  required int halfLifeDays,
  required double minimumFactor,
}) {
  if (ageDays <= 0) {
    return 1.0;
  }

  final ratio = math.exp(-ageDays / halfLifeDays);
  return minimumFactor + ((1 - minimumFactor) * ratio);
}

double _freshnessBonus(int ageDays) {
  if (ageDays <= 7) {
    return 0.08;
  }
  if (ageDays <= 21) {
    return 0.04;
  }
  return 0.0;
}

double _resolveMemorySignal({
  required double sum,
  required int count,
}) {
  final normalized = sum / math.pow(count.toDouble(), 0.74);
  return normalized.clamp(-1.0, 1.0);
}

double _resolveFatigueSignal(double sum, {required double curve}) {
  if (sum <= 0) {
    return 0.0;
  }
  return (1 - math.exp(-(sum * curve))).clamp(0.0, 1.0);
}

void _accumulateRecipeMemory({
  required Recipe recipe,
  required RecipeIngredientCanonicalizer canonicalizer,
  required double weight,
  required Map<String, double> ingredientSums,
  required Map<String, int> ingredientCounts,
  required Map<String, double> tagSums,
  required Map<String, int> tagCounts,
  required Map<String, double> pairSums,
  required Map<String, int> pairCounts,
  required Map<String, double> profileSums,
  required Map<String, int> profileCounts,
  required Map<String, double> techniqueSums,
  required Map<String, int> techniqueCounts,
}) {
  final canonicals = _recipeCanonicals(
    recipe: recipe,
    canonicalizer: canonicalizer,
  );
  for (final canonical in canonicals) {
    ingredientSums[canonical] = (ingredientSums[canonical] ?? 0.0) + weight;
    ingredientCounts[canonical] = (ingredientCounts[canonical] ?? 0) + 1;
  }
  for (final key in _pairKeysForCanonicals(canonicals)) {
    pairSums[key] = (pairSums[key] ?? 0.0) + (weight * 1.1);
    pairCounts[key] = (pairCounts[key] ?? 0) + 1;
  }

  for (final tag in recipe.tags) {
    final normalized = _normalizeTag(tag);
    if (normalized.isEmpty) {
      continue;
    }
    tagSums[normalized] = (tagSums[normalized] ?? 0.0) + (weight * 0.8);
    tagCounts[normalized] = (tagCounts[normalized] ?? 0) + 1;
  }

  final profile = inferDishProfile(
    title: recipe.title,
    tags: recipe.tags,
    ingredientCanonicals: canonicals,
  );
  profileSums[profile.name] =
      (profileSums[profile.name] ?? 0.0) + (weight * 0.9);
  profileCounts[profile.name] = (profileCounts[profile.name] ?? 0) + 1;

  final techniqueSignals =
      _extractTechniqueSignals(recipe: recipe, profile: profile);
  for (final signal in techniqueSignals) {
    techniqueSums[signal] = (techniqueSums[signal] ?? 0.0) + (weight * 0.75);
    techniqueCounts[signal] = (techniqueCounts[signal] ?? 0) + 1;
  }
}

void _accumulateRecentFatigue({
  required List<String> canonicals,
  required DishProfile profile,
  required String fingerprint,
  required double fatigueWeight,
  required Map<String, double> ingredientFatigueSums,
  required Map<String, double> profileFatigueSums,
  required Map<String, double> recipeFatigueSums,
}) {
  if (fatigueWeight <= 0) {
    return;
  }
  for (final canonical in canonicals) {
    ingredientFatigueSums[canonical] =
        (ingredientFatigueSums[canonical] ?? 0.0) + (fatigueWeight * 0.55);
  }
  profileFatigueSums[profile.name] =
      (profileFatigueSums[profile.name] ?? 0.0) + (fatigueWeight * 0.75);
  recipeFatigueSums[fingerprint] =
      (recipeFatigueSums[fingerprint] ?? 0.0) + fatigueWeight;
}

Map<String, int> _buildInteractionFrequencyMap({
  required List<RecipeInteractionEvent> interactionHistory,
  required RecipeIngredientCanonicalizer canonicalizer,
}) {
  final counts = <String, int>{};
  for (final event in interactionHistory) {
    final fingerprint = _recipeMemoryFingerprint(
      recipe: event.recipeSnapshot,
      canonicalizer: canonicalizer,
    );
    final key = _interactionFingerprintKey(event.type, fingerprint);
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return counts;
}

String _interactionFingerprintKey(
  RecipeInteractionType type,
  String fingerprint,
) {
  return '${type.storageValue}|$fingerprint';
}

String _recipeMemoryFingerprint({
  required Recipe recipe,
  required RecipeIngredientCanonicalizer canonicalizer,
  List<String>? canonicals,
  DishProfile? profile,
}) {
  final resolvedCanonicals = canonicals ??
      _recipeCanonicals(
        recipe: recipe,
        canonicalizer: canonicalizer,
      );
  final resolvedProfile = profile ??
      inferDishProfile(
        title: recipe.title,
        tags: recipe.tags,
        ingredientCanonicals: resolvedCanonicals,
      );
  return '${resolvedProfile.name}|${resolvedCanonicals.take(6).join('|')}';
}

List<String> _recipeCanonicals({
  required Recipe recipe,
  required RecipeIngredientCanonicalizer canonicalizer,
}) {
  return recipe.ingredients
      .map((ingredient) => canonicalizer.canonicalize(ingredient.name))
      .where((canonical) => canonical.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
}

List<String> _pairKeysForCanonicals(Iterable<String> canonicals) {
  final normalized = canonicals
      .map(toPairingKey)
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  final keys = <String>[];
  for (var i = 0; i < normalized.length; i++) {
    for (var j = i + 1; j < normalized.length; j++) {
      keys.add(_pairKey(normalized[i], normalized[j]));
    }
  }
  return keys;
}

String _pairKey(String first, String second) {
  final values = [toPairingKey(first), toPairingKey(second)]
    ..removeWhere((value) => value.trim().isEmpty)
    ..sort();
  return values.join('|');
}

String _normalizeTag(String raw) {
  return raw.trim().toLowerCase();
}

Set<String> _extractTechniqueSignals({
  required Recipe recipe,
  required DishProfile profile,
}) {
  final stepText = recipe.steps.map(normalizeIngredientText).join(' ');
  if (stepText.trim().isEmpty) {
    return const {};
  }

  final signals = <String>{'profile_${profile.name}'};
  if (_containsAnyKeyword(stepText, const ['обжар', 'пассер', 'прогре'])) {
    signals.add('aromatic_start');
  }
  if (_containsAnyKeyword(
      stepText, const ['слаб', 'умерен', 'под крыш', 'том'])) {
    signals.add('gentle_heat');
  }
  if (_containsAnyKeyword(
      stepText, const ['в конце', 'перед подач', 'довед', 'сразу пода'])) {
    signals.add('finish_layer');
  }
  if (_containsAnyKeyword(
      stepText, const ['соус', 'заправ', 'эмульс', 'вмеш'])) {
    signals.add('sauce_finish');
  }
  if (_containsAnyKeyword(stepText, const ['запек', 'духов'])) {
    signals.add('oven_technique');
  }
  if (_containsAnyKeyword(
      stepText, const ['отвар', 'свар', 'кип', 'ал дент', 'al dente'])) {
    signals.add('boiled_base');
  }
  if (_containsAnyKeyword(stepText, const ['дай постоять', 'отдох', 'насто'])) {
    signals.add('rested_finish');
  }
  if (_containsAnyKeyword(stepText, const ['смеш', 'заправ']) &&
      profile == DishProfile.salad) {
    signals.add('fresh_dressing');
  }
  if (_containsAnyKeyword(stepText, const ['туш', 'вар']) &&
      (profile == DishProfile.soup || profile == DishProfile.stew)) {
    signals.add('slow_build');
  }
  return signals;
}

bool _containsAnyKeyword(String text, List<String> keywords) {
  for (final keyword in keywords) {
    if (text.contains(keyword)) {
      return true;
    }
  }
  return false;
}
