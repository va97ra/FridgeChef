import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/fridge/domain/product_catalog_entry.dart';
import 'package:help_to_cook/features/recipes/domain/recipe.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_ingredient.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_nutrition.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_nutrition_estimator.dart';

void main() {
  test('estimates calories and macros from supported ingredients', () {
    final estimator = RecipeNutritionEstimator(
      catalog: const [
        ProductCatalogEntry(
          id: 'egg',
          name: 'Яйца',
          canonicalName: 'Яйцо',
          synonyms: ['яйцо', 'яйца'],
          defaultUnit: Unit.pcs,
        ),
        ProductCatalogEntry(
          id: 'milk',
          name: 'Молоко',
          canonicalName: 'Молоко',
          synonyms: ['молоко'],
          defaultUnit: Unit.l,
        ),
      ],
      references: const [
        NutritionReferenceEntry(
          canonicalName: 'яйцо',
          baseUnitKey: 'pcs',
          baseAmount: 1,
          nutrition: NutritionPerAmount(
            calories: 78,
            protein: 6.3,
            fat: 5.3,
            carbs: 0.6,
          ),
        ),
        NutritionReferenceEntry(
          canonicalName: 'молоко',
          baseUnitKey: 'ml',
          baseAmount: 100,
          nutrition: NutritionPerAmount(
            calories: 52,
            protein: 2.8,
            fat: 2.5,
            carbs: 4.7,
          ),
        ),
      ],
    );

    final estimate = estimator.estimate(
      Recipe(
        id: 'omelet',
        title: 'Омлет',
        timeMin: 10,
        tags: const ['quick'],
        servingsBase: 2,
        ingredients: const [
          RecipeIngredient(name: 'Яйца', amount: 2, unit: Unit.pcs),
          RecipeIngredient(name: 'Молоко', amount: 100, unit: Unit.ml),
        ],
        steps: const ['Смешать', 'Пожарить'],
      ),
    );

    expect(estimate.matchedIngredients, 2);
    expect(estimate.totalIngredients, 2);
    expect(estimate.coverage, 1);
    expect(estimate.total.calories, closeTo(208, 0.001));
    expect(estimate.total.protein, closeTo(15.4, 0.001));
    expect(estimate.total.fat, closeTo(13.1, 0.001));
    expect(estimate.total.carbs, closeTo(5.9, 0.001));
  });

  test('converts pieces into grams for produce references', () {
    final estimator = RecipeNutritionEstimator(
      catalog: const [
        ProductCatalogEntry(
          id: 'apple',
          name: 'Яблоки',
          canonicalName: 'Яблоко',
          synonyms: ['яблоко', 'яблоки'],
          defaultUnit: Unit.g,
        ),
      ],
      references: const [
        NutritionReferenceEntry(
          canonicalName: 'яблоко',
          baseUnitKey: 'g',
          baseAmount: 100,
          nutrition: NutritionPerAmount(
            calories: 52,
            protein: 0.3,
            fat: 0.2,
            carbs: 14,
          ),
        ),
      ],
    );

    final estimate = estimator.estimate(
      Recipe(
        id: 'apple_snack',
        title: 'Яблоко',
        timeMin: 1,
        tags: const [],
        servingsBase: 1,
        ingredients: const [
          RecipeIngredient(name: 'Яблоко', amount: 1, unit: Unit.pcs),
        ],
        steps: const ['Подать'],
      ),
    );

    expect(estimate.total.calories, closeTo(78, 0.001));
    expect(estimate.total.protein, closeTo(0.45, 0.001));
    expect(estimate.total.carbs, closeTo(21, 0.001));
  });

  test('keeps track of ingredients without nutrition reference', () {
    final estimator = RecipeNutritionEstimator(
      catalog: const [
        ProductCatalogEntry(
          id: 'egg',
          name: 'Яйца',
          canonicalName: 'Яйцо',
          synonyms: ['яйцо', 'яйца'],
          defaultUnit: Unit.pcs,
        ),
      ],
      references: const [
        NutritionReferenceEntry(
          canonicalName: 'яйцо',
          baseUnitKey: 'pcs',
          baseAmount: 1,
          nutrition: NutritionPerAmount(
            calories: 78,
            protein: 6.3,
            fat: 5.3,
            carbs: 0.6,
          ),
        ),
      ],
    );

    final estimate = estimator.estimate(
      Recipe(
        id: 'simple',
        title: 'Яйцо с лавровым листом',
        timeMin: 5,
        tags: const [],
        servingsBase: 1,
        ingredients: const [
          RecipeIngredient(name: 'Яйцо', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Лавровый лист', amount: 1, unit: Unit.g),
        ],
        steps: const ['Сварить'],
      ),
    );

    expect(estimate.matchedIngredients, 1);
    expect(estimate.totalIngredients, 2);
    expect(estimate.coverage, 0.5);
    expect(estimate.missingIngredients, ['Лавровый лист']);
  });
}
