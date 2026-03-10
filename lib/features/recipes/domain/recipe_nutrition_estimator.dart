import '../../../core/utils/units.dart';
import '../../fridge/domain/product_catalog_entry.dart';
import 'ingredient_knowledge.dart';
import 'ingredient_amount_converter.dart';
import 'recipe.dart';
import 'recipe_ingredient_canonicalizer.dart';
import 'recipe_nutrition.dart';

class RecipeNutritionEstimator {
  final RecipeIngredientCanonicalizer _canonicalizer;
  final Map<String, _IndexedNutritionReference> _references;

  RecipeNutritionEstimator({
    required List<ProductCatalogEntry> catalog,
    required List<NutritionReferenceEntry> references,
  })  : _canonicalizer = RecipeIngredientCanonicalizer(catalog),
        _references = _buildReferenceIndex(references);

  RecipeNutritionEstimate estimate(Recipe recipe) {
    var total = const NutritionPerAmount.zero();
    var matchedIngredients = 0;
    final missingIngredients = <String>[];

    for (final ingredient in recipe.ingredients) {
      final normalizedName = normalizeIngredientText(ingredient.name);
      final canonical = _canonicalizer.canonicalize(ingredient.name);
      final reference = _references[canonical] ?? _references[normalizedName];
      if (reference == null || reference.entry.baseAmount <= 0) {
        missingIngredients.add(ingredient.name);
        continue;
      }

      final convertedAmount = convertIngredientAmount(
            canonical: canonical.isNotEmpty ? canonical : normalizedName,
            amount: ingredient.amount,
            from: ingredient.unit,
            to: reference.baseUnit,
          ) ??
          UnitConverter.convert(
            amount: ingredient.amount,
            from: ingredient.unit,
            to: reference.baseUnit,
          );

      if (convertedAmount == null) {
        missingIngredients.add(ingredient.name);
        continue;
      }

      final factor = convertedAmount / reference.entry.baseAmount;
      total += reference.entry.nutrition.scale(factor);
      matchedIngredients += 1;
    }

    return RecipeNutritionEstimate(
      total: total,
      matchedIngredients: matchedIngredients,
      totalIngredients: recipe.ingredients.length,
      missingIngredients: missingIngredients,
    );
  }
}

class _IndexedNutritionReference {
  final NutritionReferenceEntry entry;
  final Unit baseUnit;

  const _IndexedNutritionReference({
    required this.entry,
    required this.baseUnit,
  });
}

Map<String, _IndexedNutritionReference> _buildReferenceIndex(
  List<NutritionReferenceEntry> references,
) {
  final index = <String, _IndexedNutritionReference>{};

  for (final reference in references) {
    final canonical = normalizeIngredientText(reference.canonicalName);
    if (canonical.isEmpty) {
      continue;
    }

    final parsedUnit = UnitExtension.fromStorage(reference.baseUnitKey);
    final indexed = _IndexedNutritionReference(
      entry: reference,
      baseUnit: parsedUnit,
    );
    index[canonical] = indexed;

    for (final alias in reference.aliases) {
      final normalizedAlias = normalizeIngredientText(alias);
      if (normalizedAlias.isEmpty) {
        continue;
      }
      index[normalizedAlias] = indexed;
    }
  }

  return index;
}
