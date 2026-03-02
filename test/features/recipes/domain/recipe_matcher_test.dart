import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/fridge/domain/fridge_item.dart';
import 'package:help_to_cook/features/recipes/domain/recipe.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_ingredient.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_matcher.dart';
import 'package:help_to_cook/features/shelf/domain/shelf_item.dart';

void main() {
  test('calculates score and missing amount by spec formula', () {
    final recipe = Recipe(
      id: 'r1',
      title: 'Тестовый рецепт',
      timeMin: 20,
      tags: const ['one_pan'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(
            name: 'Яйцо', amount: 2, unit: Unit.pcs, required: true),
        RecipeIngredient(
            name: 'Молоко', amount: 200, unit: Unit.ml, required: true),
        RecipeIngredient(
            name: 'Соль', amount: 1, unit: Unit.g, required: false),
      ],
      steps: const ['Шаг'],
    );

    final matches = matchRecipes(
      recipes: [recipe],
      fridgeItems: const [
        FridgeItem(id: '1', name: 'Яйцо', amount: 2, unit: Unit.pcs),
        FridgeItem(id: '2', name: 'Молоко', amount: 100, unit: Unit.ml),
      ],
      shelfItems: const [
        ShelfItem(id: 's1', name: 'Соль', inStock: true),
      ],
    );

    expect(matches, hasLength(1));
    final match = matches.first;
    expect(match.score, closeTo(0.625, 0.0001));
    expect(match.missingIngredients, hasLength(1));
    expect(match.missingIngredients.first.ingredient.name, 'Молоко');
    expect(match.missingIngredients.first.missingAmount, 100);
  });

  test('uses unit conversion and calculates missing amount', () {
    final recipe = Recipe(
      id: 'r2',
      title: 'Сахарный тест',
      timeMin: 10,
      tags: const ['quick'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(
            name: 'Сахар', amount: 0.5, unit: Unit.kg, required: true),
      ],
      steps: const ['Шаг'],
    );

    final matches = matchRecipes(
      recipes: [recipe],
      fridgeItems: const [
        FridgeItem(id: '1', name: 'Сахар', amount: 400, unit: Unit.g),
      ],
      shelfItems: const [],
    );

    expect(matches.first.missingIngredients.first.missingAmount,
        closeTo(0.1, 0.0001));
  });

  test('applies filters for time and tags', () {
    final quickNoOven = Recipe(
      id: 'r1',
      title: 'Быстрый без духовки',
      timeMin: 10,
      tags: const ['quick', 'no_oven'],
      servingsBase: 1,
      ingredients: const [],
      steps: const ['Шаг'],
    );
    final longRecipe = Recipe(
      id: 'r2',
      title: 'Долго',
      timeMin: 30,
      tags: const ['one_pan'],
      servingsBase: 1,
      ingredients: const [],
      steps: const ['Шаг'],
    );

    final matches = matchRecipes(
      recipes: [quickNoOven, longRecipe],
      fridgeItems: const [],
      shelfItems: const [],
      filters: const {CookFilter.upTo15Min, CookFilter.noOven},
    );

    expect(matches, hasLength(1));
    expect(matches.first.recipe.id, 'r1');
  });
}
