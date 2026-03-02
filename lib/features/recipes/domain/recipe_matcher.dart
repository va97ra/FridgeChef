import '../../../core/utils/units.dart';
import '../../fridge/domain/fridge_item.dart';
import '../../shelf/domain/shelf_item.dart';
import 'recipe.dart';
import 'recipe_match.dart';

enum CookFilter { upTo15Min, noOven, onePan }

List<RecipeMatch> matchRecipes({
  required List<Recipe> recipes,
  required List<FridgeItem> fridgeItems,
  required List<ShelfItem> shelfItems,
  Set<CookFilter> filters = const {},
}) {
  final availableByName = <String, List<_AvailableAmount>>{};
  final shelfNames = <String>{};

  for (final shelf in shelfItems) {
    if (shelf.inStock) {
      shelfNames.add(_normalizeName(shelf.name));
    }
  }

  for (final item in fridgeItems) {
    if (item.amount <= 0) {
      continue;
    }
    final key = _normalizeName(item.name);
    availableByName.putIfAbsent(key, () => []);
    availableByName[key]!
        .add(_AvailableAmount(amount: item.amount, unit: item.unit));
  }

  final matches = <RecipeMatch>[];

  for (final recipe in recipes) {
    var matchedRequired = 0;
    var totalRequired = 0;
    var matchedOptional = 0;
    var totalOptional = 0;
    final missing = <MissingIngredient>[];

    for (final ingredient in recipe.ingredients) {
      final ingredientKey = _normalizeName(ingredient.name);
      final availableAmount = shelfNames.contains(ingredientKey)
          ? ingredient.amount
          : _calculateAvailableAmount(
              ingredientKey: ingredientKey,
              ingredientUnit: ingredient.unit,
              availableByName: availableByName,
            );
      final isMatched = availableAmount >= ingredient.amount;

      if (ingredient.required) {
        totalRequired++;
        if (isMatched) {
          matchedRequired++;
        } else {
          missing.add(
            MissingIngredient(
              ingredient: ingredient,
              missingAmount: ingredient.amount - availableAmount,
            ),
          );
        }
      } else {
        totalOptional++;
        if (isMatched) {
          matchedOptional++;
        }
      }
    }

    final requiredMatch =
        totalRequired > 0 ? matchedRequired / totalRequired : 1.0;
    final optionalMatch =
        totalOptional > 0 ? matchedOptional / totalOptional : 1.0;
    var score = (0.75 * requiredMatch) + (0.25 * optionalMatch);
    if (requiredMatch == 1.0) {
      score += 0.05;
    }

    matches.add(
      RecipeMatch(
        recipe: recipe,
        score: score.clamp(0.0, 1.0),
        missingIngredients: missing,
        matchedCount: matchedRequired + matchedOptional,
        totalCount: totalRequired + totalOptional,
        matchedRequired: matchedRequired,
        totalRequired: totalRequired,
        matchedOptional: matchedOptional,
        totalOptional: totalOptional,
      ),
    );
  }

  final filtered =
      matches.where((match) => _matchesFilters(match.recipe, filters)).toList()
        ..sort((a, b) {
          final byScore = b.score.compareTo(a.score);
          if (byScore != 0) {
            return byScore;
          }
          return a.recipe.timeMin.compareTo(b.recipe.timeMin);
        });

  return filtered;
}

double _calculateAvailableAmount({
  required String ingredientKey,
  required Unit ingredientUnit,
  required Map<String, List<_AvailableAmount>> availableByName,
}) {
  final amounts = availableByName[ingredientKey];
  if (amounts == null || amounts.isEmpty) {
    return 0;
  }

  var total = 0.0;
  for (final entry in amounts) {
    final converted = UnitConverter.convert(
      amount: entry.amount,
      from: entry.unit,
      to: ingredientUnit,
    );
    if (converted != null) {
      total += converted;
    }
  }
  return total;
}

bool _matchesFilters(Recipe recipe, Set<CookFilter> filters) {
  if (filters.isEmpty) {
    return true;
  }

  final tags = recipe.tags.map((e) => e.toLowerCase()).toSet();

  if (filters.contains(CookFilter.upTo15Min) && recipe.timeMin > 15) {
    return false;
  }
  if (filters.contains(CookFilter.noOven) && !tags.contains('no_oven')) {
    return false;
  }
  if (filters.contains(CookFilter.onePan) && !tags.contains('one_pan')) {
    return false;
  }
  return true;
}

String _normalizeName(String name) => name.trim().toLowerCase();

class _AvailableAmount {
  final double amount;
  final Unit unit;

  const _AvailableAmount({
    required this.amount,
    required this.unit,
  });
}
