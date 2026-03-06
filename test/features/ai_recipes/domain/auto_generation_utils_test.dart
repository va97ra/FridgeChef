import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/ai_recipes/domain/ai_recipe.dart';
import 'package:help_to_cook/features/ai_recipes/domain/auto_generation_utils.dart';
import 'package:help_to_cook/features/fridge/domain/fridge_item.dart';
import 'package:help_to_cook/features/recipes/domain/recipe.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_ingredient.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_match.dart';
import 'package:help_to_cook/features/shelf/domain/shelf_item.dart';

void main() {
  test('computes auto recipe count by 3/4/6 rule', () {
    expect(computeAutoRecipeCount(0), 3);
    expect(computeAutoRecipeCount(3), 3);
    expect(computeAutoRecipeCount(4), 4);
    expect(computeAutoRecipeCount(8), 4);
    expect(computeAutoRecipeCount(9), 6);
  });

  test('buildInventoryFingerprint is order independent', () {
    final fridgeA = [
      const FridgeItem(
        id: '1',
        name: 'Яйца',
        amount: 4,
        unit: Unit.pcs,
      ),
      const FridgeItem(
        id: '2',
        name: 'Молоко',
        amount: 500,
        unit: Unit.ml,
      ),
    ];
    final fridgeB = fridgeA.reversed.toList();

    final shelfA = [
      const ShelfItem(id: 's1', name: 'Соль', inStock: true),
      const ShelfItem(id: 's2', name: 'Паприка', inStock: false),
    ];
    final shelfB = shelfA.reversed.toList();

    final fpA = buildInventoryFingerprint(
      fridgeItems: fridgeA,
      shelfItems: shelfA,
    );
    final fpB = buildInventoryFingerprint(
      fridgeItems: fridgeB,
      shelfItems: shelfB,
    );

    expect(fpA, fpB);
  });

  test('derivePrioritySignals prioritizes near-expiry items', () {
    final now = DateTime(2026, 3, 5);
    final signals = derivePrioritySignals(
      fridgeItems: [
        FridgeItem(
          id: '1',
          name: 'Молоко',
          amount: 400,
          unit: Unit.ml,
          expiresAt: now.add(const Duration(days: 1)),
        ),
        const FridgeItem(
          id: '2',
          name: 'Рис',
          amount: 500,
          unit: Unit.g,
        ),
      ],
      shelfItems: const [
        ShelfItem(id: 's1', name: 'Соль', inStock: true),
      ],
      now: now,
    );

    expect(signals.rankedItems, hasLength(2));
    expect(signals.rankedItems.first.normalizedName, 'молоко');
    expect(signals.priorityItems.first, 'Молоко');
  });

  test('calculates ingredient validity against allowed names', () {
    const recipes = [
      AiRecipe(
        title: 'Тест',
        timeMin: 10,
        servings: 1,
        ingredients: ['Яйца — 2 шт', 'Шпинат — 50 г'],
        steps: ['Шаг'],
      ),
    ];

    final validity = calculateIngredientValidity(
      recipes: recipes,
      allowedIngredientNames: {'яйцо', 'молоко'},
    );

    expect(validity, closeTo(0.5, 0.0001));
  });

  test('maps recipe match to deterministic AiRecipe format', () {
    final recipe = Recipe(
      id: 'r1',
      title: 'Омлет',
      timeMin: 12,
      tags: const ['quick'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(
          name: 'Яйцо',
          amount: 2,
          unit: Unit.pcs,
          required: true,
        ),
      ],
      steps: const ['Взбить', 'Пожарить'],
    );

    final match = RecipeMatch(
      recipe: recipe,
      score: 1,
      missingIngredients: const [],
      matchedCount: 1,
      totalCount: 1,
      matchedRequired: 1,
      totalRequired: 1,
      matchedOptional: 0,
      totalOptional: 0,
    );

    final aiRecipe = mapRecipeMatchToAiRecipe(match);
    expect(aiRecipe.title, 'Омлет');
    expect(aiRecipe.servings, 2);
    expect(aiRecipe.ingredients.first, 'Яйцо — 2 шт');
    expect(aiRecipe.steps, ['Взбить', 'Пожарить']);
  });

  test('buildLocalFallbackRecipes picks strong matches first and fills to count', () {
    final recipes = [
      Recipe(
        id: 'r1',
        title: 'Яичница',
        timeMin: 10,
        tags: const [],
        servingsBase: 1,
        ingredients: const [
          RecipeIngredient(name: 'Яйцо', amount: 2, unit: Unit.pcs, required: true),
        ],
        steps: const ['Шаг'],
      ),
      Recipe(
        id: 'r2',
        title: 'Салат',
        timeMin: 8,
        tags: const [],
        servingsBase: 1,
        ingredients: const [
          RecipeIngredient(name: 'Огурец', amount: 100, unit: Unit.g, required: true),
        ],
        steps: const ['Шаг'],
      ),
    ];

    final result = buildLocalFallbackRecipes(
      recipes: recipes,
      fridgeItems: const [
        FridgeItem(id: 'f1', name: 'Яйцо', amount: 4, unit: Unit.pcs),
      ],
      shelfItems: const [],
      count: 2,
    );

    expect(result, hasLength(2));
    expect(result.first.title, 'Яичница');
  });
}
