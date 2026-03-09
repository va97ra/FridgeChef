import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/ai_recipes/domain/ai_recipe.dart';
import 'package:help_to_cook/features/recipes/data/ai_to_recipe_parser.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_ingredient.dart';

void main() {
  const parser = AiToRecipeParser();

  test('parses common ingredient formats and units', () {
    const aiRecipe = AiRecipe(
      title: 'Тестовый рецепт',
      timeMin: 20,
      servings: 2,
      ingredients: [
        'Яйца — 3 шт',
        'Молоко - 200 мл',
        'Сыр - 150г',
        'Соль — по вкусу',
      ],
      steps: ['Шаг 1'],
    );

    final draft = parser.parse(aiRecipe);
    expect(draft.ingredients.length, 4);

    expect(draft.ingredients[0].name, 'Яйца');
    expect(draft.ingredients[0].amount, 3);
    expect(draft.ingredients[0].unit, Unit.pcs);
    expect(draft.ingredients[0].required, isTrue);

    expect(draft.ingredients[1].name, 'Молоко');
    expect(draft.ingredients[1].amount, 200);
    expect(draft.ingredients[1].unit, Unit.ml);
    expect(draft.ingredients[1].required, isTrue);

    expect(draft.ingredients[2].name, 'Сыр');
    expect(draft.ingredients[2].amount, 150);
    expect(draft.ingredients[2].unit, Unit.g);
    expect(draft.ingredients[2].required, isTrue);

    expect(draft.ingredients[3].name, 'Соль');
    expect(draft.ingredients[3].amount, 1);
    expect(draft.ingredients[3].unit, Unit.pcs);
    expect(draft.ingredients[3].required, isFalse);
  });

  test('keeps non-regular ingredient lines with safe fallback', () {
    const aiRecipe = AiRecipe(
      title: 'Нестандартный',
      timeMin: 15,
      servings: 2,
      ingredients: ['*** необычный ингредиент ???'],
      steps: ['Шаг 1'],
    );

    final draft = parser.parse(aiRecipe);
    expect(draft.ingredients.length, 1);
    expect(draft.ingredients.first.name, '*** необычный ингредиент ???');
    expect(draft.ingredients.first.amount, 1);
    expect(draft.ingredients.first.unit, Unit.pcs);
    expect(draft.ingredients.first.required, isFalse);
  });

  test('builds deterministic signature for normalized data', () {
    final signatureA = buildRecipeSignature(
      title: '  Омлет ',
      ingredients: const [
        RecipeIngredient(name: 'Молоко', amount: 200, unit: Unit.ml),
        RecipeIngredient(name: 'Яйцо', amount: 2, unit: Unit.pcs),
      ],
      steps: const [' Взбей ', 'Пожарь'],
    );

    final signatureB = buildRecipeSignature(
      title: 'омлет',
      ingredients: const [
        RecipeIngredient(name: 'Яйцо', amount: 2, unit: Unit.pcs),
        RecipeIngredient(name: 'Молоко', amount: 200, unit: Unit.ml),
      ],
      steps: const ['взбей', 'пожарь'],
    );

    expect(signatureA, signatureB);
  });

  test('keeps AI tip as recipe description when present', () {
    const aiRecipe = AiRecipe(
      title: 'Омлет',
      timeMin: 10,
      servings: 2,
      ingredients: ['Яйца - 2 шт'],
      steps: ['Пожарить'],
      tip: 'Нежный завтрак, который лучше готовить на слабом огне.',
    );

    final draft = parser.parse(aiRecipe);
    expect(
      draft.description,
      'Нежный завтрак, который лучше готовить на слабом огне.',
    );
  });
}
