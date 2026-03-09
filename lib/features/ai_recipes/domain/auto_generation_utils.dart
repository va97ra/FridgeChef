import '../../../core/utils/units.dart';
import '../../fridge/domain/fridge_item.dart';
import '../../fridge/domain/product_catalog_entry.dart';
import '../../recipes/domain/ingredient_knowledge.dart';
import '../../recipes/domain/recipe.dart';
import '../../recipes/domain/recipe_match.dart';
import '../../recipes/domain/recipe_matcher.dart';
import '../../shelf/domain/shelf_item.dart';
import 'ai_recipe.dart';

const double kAiIngredientValidityThreshold = 0.65;

class PriorityItemScore {
  final String name;
  final String normalizedName;
  final double priorityScore;
  final int expiryScore;
  final int pairScore;

  const PriorityItemScore({
    required this.name,
    required this.normalizedName,
    required this.priorityScore,
    required this.expiryScore,
    required this.pairScore,
  });
}

class PrioritySignals {
  final List<PriorityItemScore> rankedItems;
  final List<String> priorityItems;
  final List<String> pairHints;

  const PrioritySignals({
    required this.rankedItems,
    required this.priorityItems,
    required this.pairHints,
  });
}

int computeAutoRecipeCount(int fridgeCount) {
  if (fridgeCount < 4) {
    return 3;
  }
  if (fridgeCount <= 8) {
    return 4;
  }
  return 6;
}

String buildInventoryFingerprint({
  required List<FridgeItem> fridgeItems,
  required List<ShelfItem> shelfItems,
}) {
  final rows = <String>[];

  for (final item in fridgeItems) {
    if (item.amount <= 0) {
      continue;
    }
    rows.add(
      'f|${normalizeFoodText(item.name)}|${_formatNumber(item.amount)}|${item.unit.name}|'
      '${item.expiresAt == null ? 'none' : _dayStamp(item.expiresAt!)}|'
      '${item.calories?.toString() ?? 'none'}',
    );
  }

  for (final item in shelfItems) {
    rows.add('s|${normalizeFoodText(item.name)}|${item.inStock ? 1 : 0}');
  }

  rows.sort();
  return rows.join('||');
}

Set<String> buildAllowedIngredientNames({
  required List<FridgeItem> fridgeItems,
  required List<ShelfItem> shelfItems,
}) {
  final result = <String>{};
  for (final item in fridgeItems) {
    if (item.amount > 0) {
      result.add(normalizeFoodText(item.name));
    }
  }
  for (final item in shelfItems) {
    if (item.inStock) {
      result.add(normalizeFoodText(item.name));
    }
  }
  result.removeWhere((e) => e.isEmpty);
  return result;
}

PrioritySignals derivePrioritySignals({
  required List<FridgeItem> fridgeItems,
  required List<ShelfItem> shelfItems,
  DateTime? now,
}) {
  final activeFridge = fridgeItems.where((e) => e.amount > 0).toList();
  if (activeFridge.isEmpty) {
    return const PrioritySignals(
      rankedItems: [],
      priorityItems: [],
      pairHints: [],
    );
  }

  final availableNames = buildAllowedIngredientNames(
    fridgeItems: fridgeItems,
    shelfItems: shelfItems,
  );
  final displayByNormalized = <String, String>{};
  for (final item in activeFridge) {
    final key = normalizeFoodText(item.name);
    displayByNormalized.putIfAbsent(key, () => item.name.trim());
  }
  for (final item in shelfItems.where((e) => e.inStock)) {
    final key = normalizeFoodText(item.name);
    displayByNormalized.putIfAbsent(key, () => item.name.trim());
  }

  final ranked = activeFridge.map((item) {
    final normalized = normalizeFoodText(item.name);
    final expiryScore = expiryScoreFor(item.expiresAt, now: now);
    final pairScore = _pairScoreFor(normalized, availableNames);
    final priorityScore = (0.7 * expiryScore) + (0.3 * pairScore.clamp(0, 5));
    return PriorityItemScore(
      name: item.name.trim(),
      normalizedName: normalized,
      priorityScore: priorityScore,
      expiryScore: expiryScore,
      pairScore: pairScore,
    );
  }).toList()
    ..sort((a, b) {
      final byScore = b.priorityScore.compareTo(a.priorityScore);
      if (byScore != 0) {
        return byScore;
      }
      return a.normalizedName.compareTo(b.normalizedName);
    });

  final priorityItems = ranked.take(6).map((e) => e.name).toList();

  final scoreByName = <String, double>{
    for (final item in ranked) item.normalizedName: item.priorityScore,
  };
  final pairCandidates = <_PairCandidate>[];
  final availableList = availableNames.toList()..sort();
  for (var i = 0; i < availableList.length; i++) {
    for (var j = i + 1; j < availableList.length; j++) {
      final a = availableList[i];
      final b = availableList[j];
      final paired = pairedIngredientsFor(a).contains(toPairingKey(b)) ||
          pairedIngredientsFor(b).contains(toPairingKey(a));
      if (!paired) {
        continue;
      }
      final score = (scoreByName[a] ?? 1.0) + (scoreByName[b] ?? 1.0);
      final title =
          '${displayByNormalized[a] ?? a} + ${displayByNormalized[b] ?? b}';
      pairCandidates.add(_PairCandidate(title: title, score: score));
    }
  }

  pairCandidates.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) {
      return byScore;
    }
    return a.title.compareTo(b.title);
  });

  final pairHints = pairCandidates.map((e) => e.title).take(5).toList();

  return PrioritySignals(
    rankedItems: ranked,
    priorityItems: priorityItems,
    pairHints: pairHints,
  );
}

double calculateIngredientValidity({
  required List<AiRecipe> recipes,
  required Set<String> allowedIngredientNames,
}) {
  var total = 0;
  var matched = 0;

  for (final recipe in recipes) {
    for (final ingredient in recipe.ingredients) {
      final normalizedLine = normalizeFoodText(ingredient);
      if (normalizedLine.isEmpty) {
        continue;
      }
      total++;
      if (_isIngredientAllowed(normalizedLine, allowedIngredientNames)) {
        matched++;
      }
    }
  }

  if (total == 0) {
    return 0;
  }
  return matched / total;
}

List<AiRecipe> buildLocalFallbackRecipes({
  required List<Recipe> recipes,
  required List<FridgeItem> fridgeItems,
  required List<ShelfItem> shelfItems,
  required int count,
  List<ProductCatalogEntry> catalog = const [],
}) {
  final matches = matchRecipes(
    recipes: recipes,
    fridgeItems: fridgeItems,
    shelfItems: shelfItems,
    catalog: catalog,
  );

  if (matches.isEmpty) {
    return const [];
  }

  final selected = <RecipeMatch>[];
  final selectedIds = <String>{};

  for (final match in matches.where((m) => m.score >= 0.35)) {
    if (selected.length >= count) {
      break;
    }
    if (selectedIds.add(match.recipe.id)) {
      selected.add(match);
    }
  }

  if (selected.length < count) {
    for (final match in matches) {
      if (selected.length >= count) {
        break;
      }
      if (selectedIds.add(match.recipe.id)) {
        selected.add(match);
      }
    }
  }

  return selected
      .take(count)
      .map((match) => mapRecipeMatchToAiRecipe(match))
      .toList();
}

AiRecipe mapRecipeMatchToAiRecipe(RecipeMatch match) {
  final recipe = match.recipe;
  final ingredients = recipe.ingredients
      .map((ingredient) =>
          '${ingredient.name} — ${formatAmount(ingredient.amount, ingredient.unit)}')
      .toList();

  String? tip;
  if (match.missingIngredients.isEmpty) {
    tip = 'Все обязательные ингредиенты есть.';
  } else {
    final missingPreview = match.missingIngredients
        .take(2)
        .map(
          (missing) =>
              '${missing.ingredient.name} ${formatAmount(missing.missingAmount, missing.ingredient.unit)}',
        )
        .join(', ');
    tip = 'Не хватает: $missingPreview';
  }

  return AiRecipe(
    title: recipe.title,
    timeMin: recipe.timeMin,
    servings: recipe.servingsBase,
    ingredients: ingredients,
    steps: List<String>.from(recipe.steps),
    tip: tip,
  );
}

String formatAmount(double amount, Unit unit) {
  if (amount == amount.truncateToDouble()) {
    return '${amount.toInt()} ${unit.label}';
  }
  return '${amount.toStringAsFixed(1)} ${unit.label}';
}

int expiryScoreFor(DateTime? expiresAt, {DateTime? now}) {
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

String normalizeFoodText(String raw) {
  return normalizeIngredientText(raw);
}

bool _isIngredientAllowed(String normalizedLine, Set<String> allowedNames) {
  for (final allowedName in allowedNames) {
    if (allowedName.isEmpty) {
      continue;
    }
    if (normalizedLine.contains(allowedName) ||
        allowedName.contains(normalizedLine)) {
      return true;
    }
    final parts = allowedName.split(' ');
    if (parts.length > 1 && parts.every(normalizedLine.contains)) {
      return true;
    }
  }
  return false;
}

int _pairScoreFor(String normalizedName, Set<String> availableNames) {
  return countKnownPairings(normalizedName, availableNames);
}

String _formatNumber(double value) {
  if (value == value.truncateToDouble()) {
    return value.toInt().toString();
  }
  return value
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _dayStamp(DateTime dateTime) {
  final local = DateTime(dateTime.year, dateTime.month, dateTime.day);
  final mm = local.month.toString().padLeft(2, '0');
  final dd = local.day.toString().padLeft(2, '0');
  return '${local.year}-$mm-$dd';
}

class _PairCandidate {
  final String title;
  final double score;

  const _PairCandidate({
    required this.title,
    required this.score,
  });
}
