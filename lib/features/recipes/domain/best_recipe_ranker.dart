import '../../../core/utils/units.dart';
import '../../fridge/domain/fridge_item.dart';
import '../../fridge/domain/product_catalog_entry.dart';
import '../../shelf/domain/shelf_item.dart';
import 'chef_rules.dart';
import 'cook_filter.dart';
import 'ingredient_knowledge.dart';
import 'recipe.dart';
import 'recipe_match.dart';
import 'recipe_ingredient_canonicalizer.dart';
import 'taste_profile.dart';

class RankedRecipeCandidate {
  final Recipe recipe;
  final RecipeMatchSource source;

  const RankedRecipeCandidate({
    required this.recipe,
    required this.source,
  });
}

List<RecipeMatch> rankBestRecipes({
  required List<Recipe> recipes,
  required List<FridgeItem> fridgeItems,
  required List<ShelfItem> shelfItems,
  required List<ProductCatalogEntry> catalog,
  List<Recipe> generatedRecipes = const [],
  Set<CookFilter> filters = const {},
  DateTime? now,
  TasteProfile tasteProfile = const TasteProfile.empty(),
}) {
  final ranker = BestRecipeRanker(
    canonicalizer: RecipeIngredientCanonicalizer(catalog),
    now: now,
    tasteProfile: tasteProfile,
  );
  final candidates = <RankedRecipeCandidate>[
    ...recipes.map(
      (recipe) => RankedRecipeCandidate(
        recipe: recipe,
        source: RecipeMatchSource.base,
      ),
    ),
    ...generatedRecipes.map(
      (recipe) => RankedRecipeCandidate(
        recipe: recipe,
        source: RecipeMatchSource.generated,
      ),
    ),
  ];

  return ranker.rank(
    candidates: candidates,
    fridgeItems: fridgeItems,
    shelfItems: shelfItems,
    filters: filters,
  );
}

class BestRecipeRanker {
  final RecipeIngredientCanonicalizer canonicalizer;
  final DateTime? now;
  final TasteProfile tasteProfile;

  const BestRecipeRanker({
    required this.canonicalizer,
    this.now,
    this.tasteProfile = const TasteProfile.empty(),
  });

  List<RecipeMatch> rank({
    required List<RankedRecipeCandidate> candidates,
    required List<FridgeItem> fridgeItems,
    required List<ShelfItem> shelfItems,
    Set<CookFilter> filters = const {},
  }) {
    final inventory = _InventorySnapshot.build(
      canonicalizer: canonicalizer,
      fridgeItems: fridgeItems,
      shelfItems: shelfItems,
      now: now,
    );

    final matches = <RecipeMatch>[];
    for (final candidate in candidates) {
      if (!matchesCookFilters(candidate.recipe, filters)) {
        continue;
      }

      final match = _scoreCandidate(candidate, inventory);
      if (match != null) {
        matches.add(match);
      }
    }

    matches.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) {
        return byScore;
      }
      final byTechnique = b.techniqueScore.compareTo(a.techniqueScore);
      if (byTechnique != 0) {
        return byTechnique;
      }
      final byCompleteness = b.completenessScore.compareTo(a.completenessScore);
      if (byCompleteness != 0) {
        return byCompleteness;
      }
      final byFlavor = b.flavorScore.compareTo(a.flavorScore);
      if (byFlavor != 0) {
        return byFlavor;
      }
      final byRequired = b.matchedRequired.compareTo(a.matchedRequired);
      if (byRequired != 0) {
        return byRequired;
      }
      final byMissing =
          a.missingIngredients.length.compareTo(b.missingIngredients.length);
      if (byMissing != 0) {
        return byMissing;
      }
      final byTime = a.recipe.timeMin.compareTo(b.recipe.timeMin);
      if (byTime != 0) {
        return byTime;
      }
      return a.recipe.title.compareTo(b.recipe.title);
    });

    return matches;
  }

  RecipeMatch? _scoreCandidate(
    RankedRecipeCandidate candidate,
    _InventorySnapshot inventory,
  ) {
    final recipe = candidate.recipe;
    var matchedRequired = 0;
    var totalRequired = 0;
    var matchedOptional = 0;
    var totalOptional = 0;
    final missing = <MissingIngredient>[];
    final requiredRatios = <double>[];
    final optionalRatios = <double>[];
    final requiredGapRatios = <double>[];
    final usedCanonicals = <String>{};
    final recipeCanonicals = <String>{};
    final displayByCanonical = <String, String>{};
    final usedPriorityWeights = <String, double>{};

    for (final ingredient in recipe.ingredients) {
      final canonical = canonicalizer.canonicalize(
        ingredient.name,
        extraKnownNames: inventory.knownNames,
      );
      if (canonical.isNotEmpty) {
        recipeCanonicals.add(canonical);
        displayByCanonical.putIfAbsent(canonical, () => ingredient.name.trim());
      }

      final availableAmount = inventory.availableAmountFor(
        canonical: canonical,
        targetUnit: ingredient.unit,
      );
      final ratio = ingredient.amount <= 0
          ? 1.0
          : (availableAmount / ingredient.amount).clamp(0.0, 1.0);
      final isMatched = ratio >= 0.999;

      if (ratio >= (ingredient.required ? 0.75 : 0.55)) {
        usedCanonicals.add(canonical);
      }
      final priorityWeight = inventory.priorityWeights[canonical];
      if (priorityWeight != null && ratio >= 0.5) {
        usedPriorityWeights[canonical] = priorityWeight;
      }

      if (ingredient.required) {
        totalRequired++;
        requiredRatios.add(ratio);
        requiredGapRatios.add(1 - ratio);
        if (isMatched) {
          matchedRequired++;
        } else {
          missing.add(
            MissingIngredient(
              ingredient: ingredient,
              missingAmount: (ingredient.amount - availableAmount)
                  .clamp(0.0, ingredient.amount),
            ),
          );
        }
      } else {
        totalOptional++;
        optionalRatios.add(ratio);
        if (isMatched) {
          matchedOptional++;
        }
      }
    }

    final coverageScore = _coverageScore(
      requiredRatios: requiredRatios,
      optionalRatios: optionalRatios,
      matchedRequired: matchedRequired,
      totalRequired: totalRequired,
    );
    final pairAnalysis = _pairingAnalysis(
      usedCanonicals: usedCanonicals,
      displayByCanonical: displayByCanonical,
    );
    final chefAssessment = assessChefRules(
      profile: inferDishProfile(
        title: recipe.title,
        tags: recipe.tags,
        ingredientCanonicals: recipeCanonicals,
      ),
      recipeCanonicals: recipeCanonicals,
      matchedCanonicals: usedCanonicals,
      supportCanonicals: inventory.shelfSupportCanonicals,
      displayByCanonical: {
        ...inventory.displayByCanonical,
        ...displayByCanonical,
      },
      steps: recipe.steps,
    );
    final personalAnalysis = tasteProfile.analyzeRecipe(
      recipe: recipe,
      canonicalizer: canonicalizer,
    );
    final priorityUsageScore = _priorityUsageScore(
      usedPriorityWeights: usedPriorityWeights,
      inventory: inventory,
    );
    final completenessScore = _completenessScore(
      recipe: recipe,
      coverageScore: coverageScore,
      pairingScore: pairAnalysis.score,
      chefAssessment: chefAssessment,
      matchedRequired: matchedRequired,
      totalRequired: totalRequired,
    );
    final effortFitScore = _effortFitScore(recipe);

    var totalScore = (coverageScore * 0.35) +
        (pairAnalysis.score * 0.30) +
        (priorityUsageScore * 0.20) +
        (completenessScore * 0.10) +
        (effortFitScore * 0.05);
    totalScore *= pairAnalysis.hardPenalty;
    totalScore =
        ((totalScore * 0.90) + (personalAnalysis.score * 0.10)).clamp(0.0, 1.0);

    final missingRequired = totalRequired - matchedRequired;
    final worstGap = requiredGapRatios.isEmpty
        ? 0.0
        : requiredGapRatios.reduce((a, b) => a > b ? a : b);
    if (missingRequired > 0) {
      final severePenalty = missingRequired > 1 || worstGap > 0.45;
      totalScore *= severePenalty ? 0.55 : 0.78;
    } else if (totalRequired > 0) {
      totalScore = (totalScore + 0.04).clamp(0.0, 1.0);
    }

    if (chefAssessment.score < 0.42) {
      totalScore *= 0.82;
    } else if (chefAssessment.score >= 0.72) {
      totalScore = (totalScore + 0.03).clamp(0.0, 1.0);
    }
    if (chefAssessment.techniqueScore < 0.34) {
      totalScore *= 0.84;
    } else if (chefAssessment.techniqueScore >= 0.72) {
      totalScore = (totalScore + 0.02).clamp(0.0, 1.0);
    }
    if (chefAssessment.flavorScore < 0.34) {
      totalScore *= 0.84;
    } else if (chefAssessment.flavorScore >= 0.72) {
      totalScore = (totalScore + 0.02).clamp(0.0, 1.0);
    }

    if (candidate.source == RecipeMatchSource.generated &&
        (pairAnalysis.score < 0.18 ||
            pairAnalysis.forbiddenPairs > 0 ||
            completenessScore < 0.45 ||
            chefAssessment.score < 0.45 ||
            chefAssessment.flavorScore < 0.32 ||
            personalAnalysis.score < 0.12)) {
      return null;
    }

    return RecipeMatch(
      recipe: recipe,
      source: candidate.source,
      score: totalScore.clamp(0.0, 1.0),
      coverageScore: coverageScore,
      pairingScore: pairAnalysis.score,
      priorityUsageScore: priorityUsageScore,
      completenessScore: completenessScore,
      seasoningScore: chefAssessment.seasoningScore,
      techniqueScore: chefAssessment.techniqueScore,
      effortFitScore: effortFitScore,
      personalScore: personalAnalysis.score,
      flavorScore: chefAssessment.flavorScore,
      why: _buildReasons(
        recipe: recipe,
        matchedRequired: matchedRequired,
        totalRequired: totalRequired,
        pairAnalysis: pairAnalysis,
        chefAssessment: chefAssessment,
        personalAnalysis: personalAnalysis,
        usedPriorityCanonicals: usedPriorityWeights.keys.toList(),
        inventory: inventory,
      ),
      missingIngredients: missing,
      matchedCount: matchedRequired + matchedOptional,
      totalCount: totalRequired + totalOptional,
      matchedRequired: matchedRequired,
      totalRequired: totalRequired,
      matchedOptional: matchedOptional,
      totalOptional: totalOptional,
    );
  }

  double _coverageScore({
    required List<double> requiredRatios,
    required List<double> optionalRatios,
    required int matchedRequired,
    required int totalRequired,
  }) {
    final requiredCoverage = requiredRatios.isEmpty
        ? 1.0
        : requiredRatios.reduce((a, b) => a + b) / requiredRatios.length;
    final optionalCoverage = optionalRatios.isEmpty
        ? 1.0
        : optionalRatios.reduce((a, b) => a + b) / optionalRatios.length;

    var score = (requiredCoverage * 0.85) + (optionalCoverage * 0.15);
    if (totalRequired > 0 && matchedRequired == totalRequired) {
      score += 0.08;
    }
    return score.clamp(0.0, 1.0);
  }

  _PairingAnalysis _pairingAnalysis({
    required Set<String> usedCanonicals,
    required Map<String, String> displayByCanonical,
  }) {
    final pairKeys = usedCanonicals.map(toPairingKey).toSet().toList()..sort();
    if (pairKeys.length < 2) {
      return const _PairingAnalysis(score: 0.14);
    }

    var totalPairs = 0;
    var strongPairs = 0;
    var weakPairs = 0;
    var forbiddenPairs = 0;
    String? bestPairLabel;

    for (var i = 0; i < pairKeys.length; i++) {
      for (var j = i + 1; j < pairKeys.length; j++) {
        totalPairs++;
        final a = pairKeys[i];
        final b = pairKeys[j];
        final paired = pairedIngredientsFor(a).contains(b) ||
            pairedIngredientsFor(b).contains(a);
        final weak = weaklyPairedIngredientsFor(a).contains(b) ||
            weaklyPairedIngredientsFor(b).contains(a);
        final forbidden = forbiddenPairingsFor(a).contains(b) ||
            forbiddenPairingsFor(b).contains(a);
        if (paired) {
          strongPairs++;
          bestPairLabel ??=
              '${displayByCanonical[a] ?? a} + ${displayByCanonical[b] ?? b}';
        }
        if (forbidden) {
          forbiddenPairs++;
        } else if (weak) {
          weakPairs++;
        }
      }
    }

    var score = strongPairs == 0
        ? (0.08 * pairKeys.length).clamp(0.08, 0.24)
        : (strongPairs / totalPairs).clamp(0.0, 1.0);
    score -= (weakPairs / totalPairs) * 0.22;
    score -= (forbiddenPairs / totalPairs) * 0.55;

    var hardPenalty = 1.0;
    if (forbiddenPairs > 0) {
      hardPenalty *= 0.58;
    } else if (weakPairs > 1) {
      hardPenalty *= 0.84;
    } else if (weakPairs == 1) {
      hardPenalty *= 0.92;
    }

    return _PairingAnalysis(
      score: score.clamp(0.0, 1.0),
      bestPairLabel: bestPairLabel,
      weakPairs: weakPairs,
      forbiddenPairs: forbiddenPairs,
      hardPenalty: hardPenalty,
    );
  }

  double _priorityUsageScore({
    required Map<String, double> usedPriorityWeights,
    required _InventorySnapshot inventory,
  }) {
    if (inventory.priorityWeights.isEmpty) {
      return 0.5;
    }

    final maxWeight = inventory.priorityWeights.values.fold<double>(
      0.0,
      (sum, value) => sum + value,
    );
    if (maxWeight <= 0) {
      return 0.5;
    }

    final usedWeight = usedPriorityWeights.values.fold<double>(
      0.0,
      (sum, value) => sum + value,
    );
    final urgentBonus = usedPriorityWeights.keys.any(
      (canonical) => (inventory.expiryScores[canonical] ?? 0) >= 4,
    );

    var score = usedWeight / maxWeight;
    if (urgentBonus && score > 0) {
      score += 0.1;
    }
    return score.clamp(0.0, 1.0);
  }

  double _completenessScore({
    required Recipe recipe,
    required double coverageScore,
    required double pairingScore,
    required ChefRulesAssessment chefAssessment,
    required int matchedRequired,
    required int totalRequired,
  }) {
    var score = 0.22 + (coverageScore * 0.28);

    if (totalRequired == 0 || matchedRequired == totalRequired) {
      score += 0.16;
    }
    if (recipe.ingredients.length >= 3 && recipe.ingredients.length <= 7) {
      score += 0.08;
    } else if (recipe.ingredients.length == 2) {
      score += 0.06;
    }
    if (recipe.steps.length >= 3) {
      score += 0.08;
    } else if (recipe.steps.length == 2) {
      score += 0.04;
    }
    if (pairingScore >= 0.35) {
      score += 0.1;
    }

    final chefBlend = (chefAssessment.structureScore * 0.50) +
        (chefAssessment.seasoningScore * 0.15) +
        (chefAssessment.techniqueScore * 0.15) +
        (chefAssessment.balanceScore * 0.10) +
        (chefAssessment.flavorScore * 0.10);

    return ((score * 0.58) + (chefBlend * 0.42)).clamp(0.0, 1.0);
  }

  double _effortFitScore(Recipe recipe) {
    var score = 1.0;
    if (recipe.timeMin > 15) {
      score -= 0.15;
    }
    if (recipe.timeMin > 30) {
      score -= 0.15;
    }
    if (recipe.timeMin > 45) {
      score -= 0.15;
    }
    if (recipe.steps.length > 4) {
      score -= (recipe.steps.length - 4) * 0.04;
    }

    final tags = recipe.tags.map((tag) => tag.toLowerCase()).toSet();
    if (tags.contains('one_pan')) {
      score += 0.06;
    }
    if (tags.contains('no_oven')) {
      score += 0.04;
    }

    return score.clamp(0.0, 1.0);
  }

  List<String> _buildReasons({
    required Recipe recipe,
    required int matchedRequired,
    required int totalRequired,
    required _PairingAnalysis pairAnalysis,
    required ChefRulesAssessment chefAssessment,
    required TasteProfileAnalysis personalAnalysis,
    required List<String> usedPriorityCanonicals,
    required _InventorySnapshot inventory,
  }) {
    final reasons = <String>[];

    if (totalRequired == 0 || matchedRequired == totalRequired) {
      reasons.add('все продукты есть дома');
    } else if (matchedRequired >= totalRequired - 1) {
      reasons.add('не хватает совсем немного');
    }

    if (pairAnalysis.bestPairLabel != null) {
      reasons.add('сильное сочетание ${pairAnalysis.bestPairLabel}');
    }

    for (final chefReason in chefAssessment.reasons) {
      if (reasons.length >= 3) {
        break;
      }
      if (!reasons.contains(chefReason)) {
        reasons.add(chefReason);
      }
    }

    for (final personalReason in personalAnalysis.reasons) {
      if (reasons.length >= 3) {
        break;
      }
      if (!reasons.contains(personalReason)) {
        reasons.add(personalReason);
      }
    }

    if (usedPriorityCanonicals.isNotEmpty) {
      final display = usedPriorityCanonicals
          .map((name) => inventory.displayByCanonical[name] ?? name)
          .take(2)
          .join(', ');
      reasons.add('использует скоропорт: $display');
    }

    if (reasons.length < 3) {
      if (recipe.timeMin <= 15) {
        reasons.add('готовится быстро');
      } else if (recipe.tags
          .map((tag) => tag.toLowerCase())
          .contains('one_pan')) {
        reasons.add('готовится в одной посуде');
      }
    }

    return reasons.take(3).toList();
  }
}

class _InventorySnapshot {
  final Map<String, List<_AvailableAmount>> fridgeByCanonical;
  final Set<String> shelfCanonicals;
  final Set<String> shelfSupportCanonicals;
  final Set<String> knownNames;
  final Map<String, double> priorityWeights;
  final Map<String, int> expiryScores;
  final Map<String, String> displayByCanonical;

  const _InventorySnapshot({
    required this.fridgeByCanonical,
    required this.shelfCanonicals,
    required this.shelfSupportCanonicals,
    required this.knownNames,
    required this.priorityWeights,
    required this.expiryScores,
    required this.displayByCanonical,
  });

  factory _InventorySnapshot.build({
    required RecipeIngredientCanonicalizer canonicalizer,
    required List<FridgeItem> fridgeItems,
    required List<ShelfItem> shelfItems,
    DateTime? now,
  }) {
    final fridgeByCanonical = <String, List<_AvailableAmount>>{};
    final shelfCanonicals = <String>{};
    final shelfSupportCanonicals = <String>{};
    final displayByCanonical = <String, String>{};
    final knownNames = <String>{};
    final expiryScores = <String, int>{};

    for (final item in fridgeItems) {
      if (item.amount <= 0) {
        continue;
      }
      final canonical = canonicalizer.canonicalize(item.name);
      if (canonical.isEmpty) {
        continue;
      }
      knownNames.add(canonical);
      displayByCanonical.putIfAbsent(canonical, () => item.name.trim());
      fridgeByCanonical.putIfAbsent(canonical, () => []);
      fridgeByCanonical[canonical]!.add(
        _AvailableAmount(amount: item.amount, unit: item.unit),
      );

      final expiryScore = _expiryScoreFor(item.expiresAt, now: now);
      final existing = expiryScores[canonical];
      if (existing == null || expiryScore > existing) {
        expiryScores[canonical] = expiryScore;
      }
    }

    for (final item in shelfItems) {
      if (!item.inStock) {
        continue;
      }
      final rawCanonical =
          item.canonicalName.trim().isNotEmpty ? item.canonicalName : item.name;
      final canonical = toPairingKey(rawCanonical);
      if (canonical.isEmpty) {
        continue;
      }
      knownNames.add(canonical);
      displayByCanonical.putIfAbsent(canonical, () => item.name.trim());
      shelfCanonicals.add(canonical);
      shelfSupportCanonicals.add(canonical);
      for (final support in item.supportCanonicals) {
        final normalizedSupport = toPairingKey(support);
        if (normalizedSupport.isNotEmpty) {
          shelfSupportCanonicals.add(normalizedSupport);
        }
      }
    }

    final priorityWeights = <String, double>{};
    final availableForPairs = {...fridgeByCanonical.keys, ...shelfCanonicals};
    for (final canonical in fridgeByCanonical.keys) {
      final expiryScore = expiryScores[canonical] ?? 1;
      final pairScore = countKnownPairings(canonical, availableForPairs)
          .clamp(0, 5)
          .toDouble();
      priorityWeights[canonical] = (0.7 * expiryScore) + (0.3 * pairScore);
    }

    return _InventorySnapshot(
      fridgeByCanonical: fridgeByCanonical,
      shelfCanonicals: shelfCanonicals,
      shelfSupportCanonicals: shelfSupportCanonicals,
      knownNames: knownNames,
      priorityWeights: priorityWeights,
      expiryScores: expiryScores,
      displayByCanonical: displayByCanonical,
    );
  }

  double availableAmountFor({
    required String canonical,
    required Unit targetUnit,
  }) {
    for (final shelfKey in compatibleIngredientKeysForMatching(canonical)) {
      if (shelfCanonicals.contains(shelfKey)) {
        return 999999;
      }
    }

    var total = 0.0;
    for (final candidateKey in compatibleIngredientKeysForMatching(canonical)) {
      final entries = fridgeByCanonical[candidateKey];
      if (entries == null || entries.isEmpty) {
        continue;
      }
      for (final entry in entries) {
        final converted = _convertIngredientAmount(
          canonical: candidateKey,
          amount: entry.amount,
          from: entry.unit,
          to: targetUnit,
        );
        if (converted != null) {
          total += converted;
        }
      }
    }
    return total;
  }

  static int _expiryScoreFor(DateTime? expiresAt, {DateTime? now}) {
    if (expiresAt == null) {
      return 1;
    }

    final refDate = now ?? DateTime.now();
    final today = DateTime(refDate.year, refDate.month, refDate.day);
    final expiry = DateTime(expiresAt.year, expiresAt.month, expiresAt.day);
    final days = expiry.difference(today).inDays;

    if (days <= 1) {
      return 5;
    }
    if (days <= 3) {
      return 4;
    }
    if (days <= 7) {
      return 2;
    }
    return 1;
  }
}

double? _convertIngredientAmount({
  required String canonical,
  required double amount,
  required Unit from,
  required Unit to,
}) {
  final direct = UnitConverter.convert(amount: amount, from: from, to: to);
  if (direct != null) {
    return direct;
  }

  final gramsPerPiece = _approxMassPerPiece[canonical];
  if (gramsPerPiece == null) {
    return null;
  }

  if (from == Unit.pcs && to == Unit.g) {
    return amount * gramsPerPiece;
  }
  if (from == Unit.g && to == Unit.pcs) {
    return amount / gramsPerPiece;
  }
  if (from == Unit.pcs && to == Unit.kg) {
    return (amount * gramsPerPiece) / 1000.0;
  }
  if (from == Unit.kg && to == Unit.pcs) {
    return (amount * 1000.0) / gramsPerPiece;
  }

  return null;
}

const Map<String, double> _approxMassPerPiece = {
  'яблоко': 150,
  'банан': 120,
  'апельсин': 160,
  'лимон': 90,
  'помидор': 130,
  'огурец': 120,
  'лук': 90,
  'картофель': 150,
  'морковь': 80,
  'перец сладкий': 140,
  'кабачок': 250,
};

class _AvailableAmount {
  final double amount;
  final Unit unit;

  const _AvailableAmount({
    required this.amount,
    required this.unit,
  });
}

class _PairingAnalysis {
  final double score;
  final String? bestPairLabel;
  final int weakPairs;
  final int forbiddenPairs;
  final double hardPenalty;

  const _PairingAnalysis({
    required this.score,
    this.bestPairLabel,
    this.weakPairs = 0,
    this.forbiddenPairs = 0,
    this.hardPenalty = 1.0,
  });
}
