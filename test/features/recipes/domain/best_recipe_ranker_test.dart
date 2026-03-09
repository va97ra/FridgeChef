import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/fridge/domain/fridge_item.dart';
import 'package:help_to_cook/features/fridge/domain/product_catalog_entry.dart';
import 'package:help_to_cook/features/recipes/domain/best_recipe_ranker.dart';
import 'package:help_to_cook/features/recipes/domain/recipe.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_ingredient.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_ingredient_canonicalizer.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_interaction_event.dart';
import 'package:help_to_cook/features/recipes/domain/taste_profile.dart';
import 'package:help_to_cook/features/shelf/domain/shelf_item.dart';

void main() {
  final catalog = _loadCatalog();

  test('all asset recipe ingredients are covered by catalog canonicalization',
      () {
    final recipes = _loadRecipes();
    final canonicalizer = RecipeIngredientCanonicalizer(catalog);
    final knownCanonicals = catalog
        .map((entry) => canonicalizer.canonicalize(entry.canonicalName))
        .toSet();

    for (final recipe in recipes) {
      for (final ingredient in recipe.ingredients) {
        final canonical = canonicalizer.canonicalize(ingredient.name);
        expect(
          knownCanonicals.contains(canonical),
          isTrue,
          reason:
              'Ingredient "${ingredient.name}" from "${recipe.title}" is not covered by catalog',
        );
      }
    }
  });

  test('recipe with full required ingredients ranks above recipe with gaps',
      () {
    final complete = Recipe(
      id: 'complete',
      title: 'Омлет',
      timeMin: 10,
      tags: const ['one_pan'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Яйцо', amount: 2, unit: Unit.pcs),
        RecipeIngredient(name: 'Сыр', amount: 40, unit: Unit.g),
      ],
      steps: const ['Взбить', 'Пожарить'],
    );
    final missing = Recipe(
      id: 'missing',
      title: 'Рисовая миска',
      timeMin: 12,
      tags: const ['one_pan'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Рис', amount: 150, unit: Unit.g),
        RecipeIngredient(name: 'Тунец', amount: 100, unit: Unit.g),
      ],
      steps: const ['Смешать', 'Прогреть'],
    );

    final matches = rankBestRecipes(
      recipes: [missing, complete],
      fridgeItems: const [
        FridgeItem(id: 'f1', name: 'Яйцо', amount: 4, unit: Unit.pcs),
        FridgeItem(id: 'f2', name: 'Сыр', amount: 100, unit: Unit.g),
        FridgeItem(id: 'f3', name: 'Рис', amount: 200, unit: Unit.g),
      ],
      shelfItems: const [],
      catalog: catalog,
    );

    expect(matches.first.recipe.id, 'complete');
    expect(matches.first.missingIngredients, isEmpty);
    expect(matches.last.missingIngredients, isNotEmpty);
  });

  test('strong pairing ranks above weak pairing with similar coverage', () {
    final strong = Recipe(
      id: 'strong',
      title: 'Томаты с сыром',
      timeMin: 8,
      tags: const ['quick', 'no_oven'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Помидор', amount: 180, unit: Unit.g),
        RecipeIngredient(name: 'Сыр', amount: 50, unit: Unit.g),
      ],
      steps: const ['Нарезать', 'Смешать'],
    );
    final weak = Recipe(
      id: 'weak',
      title: 'Банан с мукой',
      timeMin: 8,
      tags: const ['quick'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Банан', amount: 1, unit: Unit.pcs),
        RecipeIngredient(name: 'Мука', amount: 50, unit: Unit.g),
      ],
      steps: const ['Смешать', 'Подать'],
    );

    final matches = rankBestRecipes(
      recipes: [weak, strong],
      fridgeItems: const [
        FridgeItem(id: 'f1', name: 'Помидоры', amount: 300, unit: Unit.g),
        FridgeItem(id: 'f2', name: 'Сыр', amount: 120, unit: Unit.g),
        FridgeItem(id: 'f3', name: 'Бананы', amount: 2, unit: Unit.pcs),
        FridgeItem(id: 'f4', name: 'Мука', amount: 300, unit: Unit.g),
      ],
      shelfItems: const [],
      catalog: catalog,
    );

    expect(matches.first.recipe.id, 'strong');
    expect(matches.first.pairingScore, greaterThan(matches.last.pairingScore));
  });

  test('priority on expiry does not outrank a clearly tastier full recipe', () {
    final now = DateTime(2026, 3, 6);
    final tasty = Recipe(
      id: 'tasty',
      title: 'Томатный салат с сыром',
      timeMin: 10,
      tags: const ['quick', 'no_oven'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Помидор', amount: 200, unit: Unit.g),
        RecipeIngredient(name: 'Сыр', amount: 40, unit: Unit.g),
      ],
      steps: const ['Нарезать', 'Смешать'],
    );
    final odd = Recipe(
      id: 'odd',
      title: 'Сладкие томаты',
      timeMin: 6,
      tags: const ['quick'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Помидор', amount: 200, unit: Unit.g),
        RecipeIngredient(name: 'Сахар', amount: 10, unit: Unit.g),
      ],
      steps: const ['Посыпать'],
    );

    final matches = rankBestRecipes(
      recipes: [odd, tasty],
      fridgeItems: [
        FridgeItem(
          id: 'f1',
          name: 'Помидоры',
          amount: 400,
          unit: Unit.g,
          expiresAt: now.add(const Duration(days: 1)),
        ),
        const FridgeItem(id: 'f2', name: 'Сыр', amount: 100, unit: Unit.g),
        const FridgeItem(id: 'f3', name: 'Сахар', amount: 500, unit: Unit.g),
      ],
      shelfItems: const [],
      catalog: catalog,
      now: now,
    );

    expect(matches.first.recipe.id, 'tasty');
    expect(matches.first.priorityUsageScore, greaterThan(0));
    expect(matches.first.pairingScore, greaterThan(matches.last.pairingScore));
  });

  test('shelf seasonings appear in reasons for savory dish', () {
    final recipe = Recipe(
      id: 'omelet',
      title: 'Омлет с сыром',
      timeMin: 10,
      tags: const ['one_pan', 'breakfast'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Яйцо', amount: 2, unit: Unit.pcs),
        RecipeIngredient(name: 'Сыр', amount: 40, unit: Unit.g),
      ],
      steps: const ['Взбей', 'Обжарь', 'Подавай'],
    );

    final matches = rankBestRecipes(
      recipes: [recipe],
      fridgeItems: const [
        FridgeItem(id: 'f1', name: 'Яйцо', amount: 4, unit: Unit.pcs),
        FridgeItem(id: 'f2', name: 'Сыр', amount: 100, unit: Unit.g),
      ],
      shelfItems: const [
        ShelfItem(id: 's1', name: 'Соль', inStock: true),
        ShelfItem(id: 's2', name: 'Перец', inStock: true),
      ],
      catalog: catalog,
    );

    expect(matches.single.seasoningScore, greaterThan(0.55));
    expect(
      matches.single.why
          .any((reason) => reason.contains('полка усиливает вкус')),
      isTrue,
    );
  });

  test('balanced salad ranks above dry chopped vegetables', () {
    final balanced = Recipe(
      id: 'balanced_salad',
      title: 'Салат с сыром',
      timeMin: 8,
      tags: const ['quick', 'light'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Огурец', amount: 150, unit: Unit.g),
        RecipeIngredient(name: 'Помидор', amount: 150, unit: Unit.g),
        RecipeIngredient(name: 'Сыр', amount: 40, unit: Unit.g),
      ],
      steps: const ['Нарежь', 'Смешай', 'Заправь и подай'],
    );
    final dry = Recipe(
      id: 'dry_salad',
      title: 'Просто огурцы и помидоры',
      timeMin: 5,
      tags: const ['quick', 'light'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Огурец', amount: 150, unit: Unit.g),
        RecipeIngredient(name: 'Помидор', amount: 150, unit: Unit.g),
      ],
      steps: const ['Нарежь', 'Смешай'],
    );

    final matches = rankBestRecipes(
      recipes: [dry, balanced],
      fridgeItems: const [
        FridgeItem(id: 'f1', name: 'Огурцы', amount: 400, unit: Unit.g),
        FridgeItem(id: 'f2', name: 'Помидоры', amount: 400, unit: Unit.g),
        FridgeItem(id: 'f3', name: 'Сыр', amount: 120, unit: Unit.g),
      ],
      shelfItems: const [
        ShelfItem(id: 's1', name: 'Оливковое масло', inStock: true),
        ShelfItem(id: 's2', name: 'Лимон', inStock: true),
        ShelfItem(id: 's3', name: 'Соль', inStock: true),
      ],
      catalog: catalog,
    );

    expect(matches.first.recipe.id, 'balanced_salad');
    expect(matches.first.seasoningScore,
        greaterThanOrEqualTo(matches.last.seasoningScore));
    expect(matches.first.completenessScore,
        greaterThan(matches.last.completenessScore));
  });

  test('generated candidate with weak pairing is dropped from ranking', () {
    final local = Recipe(
      id: 'local',
      title: 'Омлет',
      timeMin: 9,
      tags: const ['one_pan'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Яйцо', amount: 2, unit: Unit.pcs),
        RecipeIngredient(name: 'Сыр', amount: 30, unit: Unit.g),
      ],
      steps: const ['Взбить', 'Пожарить'],
    );
    final weirdGenerated = Recipe(
      id: 'generated_weird',
      title: 'Соль с сахаром',
      timeMin: 2,
      tags: const ['generated_local'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Соль', amount: 1, unit: Unit.g),
        RecipeIngredient(name: 'Сахар', amount: 1, unit: Unit.g),
      ],
      steps: const ['Смешать'],
    );

    final matches = rankBestRecipes(
      recipes: [local],
      generatedRecipes: [weirdGenerated],
      fridgeItems: const [
        FridgeItem(id: 'f1', name: 'Яйцо', amount: 4, unit: Unit.pcs),
        FridgeItem(id: 'f2', name: 'Сыр', amount: 120, unit: Unit.g),
        FridgeItem(id: 'f3', name: 'Сахар', amount: 300, unit: Unit.g),
      ],
      shelfItems: const [
        ShelfItem(id: 's1', name: 'Соль', inStock: true),
      ],
      catalog: catalog,
    );

    expect(
      matches.map((match) => match.recipe.id),
      isNot(contains('generated_weird')),
    );
    expect(matches.first.recipe.id, 'local');
  });

  test('generated reasons mention anchor urgency and pantry assumptions', () {
    final generated = Recipe(
      id: 'generated_1',
      title: 'Шеф-сковорода: Яйца, Помидоры, Сыр',
      timeMin: 12,
      tags: const ['generated_local', 'quick', 'one_pan', 'breakfast'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Яйца', amount: 3, unit: Unit.pcs),
        RecipeIngredient(name: 'Помидоры', amount: 180, unit: Unit.g),
        RecipeIngredient(name: 'Сыр', amount: 80, unit: Unit.g),
        RecipeIngredient(
            name: 'Соль', amount: 1, unit: Unit.g, required: false),
      ],
      steps: const [
        'Быстро обжарь помидоры.',
        'Влей яйца и аккуратно веди массу лопаткой.',
        'Добавь сыр и подай сразу.',
      ],
      source: RecipeSource.generatedDraft,
      anchorIngredients: ['Яйца', 'Помидоры'],
      implicitPantryItems: ['Соль'],
      chefProfile: 'skillet',
    );

    final matches = rankBestRecipes(
      recipes: const [],
      generatedRecipes: [generated],
      fridgeItems: [
        FridgeItem(
          id: 'f1',
          name: 'Яйца',
          amount: 6,
          unit: Unit.pcs,
          expiresAt: DateTime(2026, 3, 7),
        ),
        const FridgeItem(
          id: 'f2',
          name: 'Помидоры',
          amount: 400,
          unit: Unit.g,
        ),
        const FridgeItem(
          id: 'f3',
          name: 'Сыр',
          amount: 160,
          unit: Unit.g,
        ),
      ],
      shelfItems: const [],
      catalog: catalog,
      now: DateTime(2026, 3, 6),
    );

    expect(matches.single.why, contains('шеф ставит в центр Яйца, Помидоры'));
    expect(
      matches.single.why
          .any((reason) => reason.contains('лучше использовать сейчас')),
      isTrue,
    );
    expect(
      matches.single.why,
      contains('из полки нужны только Соль'),
    );
  });

  test('recent repeats push a fresh close alternative above the same dish', () {
    final now = DateTime(2026, 3, 9, 12);
    final omelet = Recipe(
      id: 'omelet',
      title: 'Омлет с сыром',
      timeMin: 9,
      tags: const ['breakfast', 'one_pan'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Яйцо', amount: 2, unit: Unit.pcs),
        RecipeIngredient(name: 'Сыр', amount: 40, unit: Unit.g),
      ],
      steps: const ['Взбей', 'Обжарь', 'Подавай'],
    );
    final shakshuka = Recipe(
      id: 'shakshuka',
      title: 'Шакшука',
      timeMin: 12,
      tags: const ['breakfast', 'one_pan'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Яйцо', amount: 2, unit: Unit.pcs),
        RecipeIngredient(name: 'Помидор', amount: 180, unit: Unit.g),
        RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
      ],
      steps: const ['Обжарь лук', 'Добавь томаты', 'Влей яйца и доведи'],
    );
    final fatigueProfile = buildTasteProfile(
      feedbackByRecipeId: const {},
      recipes: const [],
      catalog: catalog,
      interactionHistory: [
        RecipeInteractionEvent(
          type: RecipeInteractionType.recooked,
          recipeSnapshot: omelet,
          occurredAt: now.subtract(const Duration(days: 4)),
        ),
        RecipeInteractionEvent(
          type: RecipeInteractionType.recooked,
          recipeSnapshot: omelet,
          occurredAt: now.subtract(const Duration(days: 2)),
        ),
        RecipeInteractionEvent(
          type: RecipeInteractionType.recooked,
          recipeSnapshot: omelet,
          occurredAt: now.subtract(const Duration(days: 1)),
        ),
      ],
      referenceTime: now,
    );

    final fatigueMatches = rankBestRecipes(
      recipes: [omelet, shakshuka],
      fridgeItems: const [
        FridgeItem(id: 'f1', name: 'Яйцо', amount: 4, unit: Unit.pcs),
        FridgeItem(id: 'f2', name: 'Сыр', amount: 120, unit: Unit.g),
        FridgeItem(id: 'f3', name: 'Помидор', amount: 250, unit: Unit.g),
        FridgeItem(id: 'f4', name: 'Лук', amount: 2, unit: Unit.pcs),
      ],
      shelfItems: const [
        ShelfItem(id: 's1', name: 'Соль', inStock: true),
      ],
      catalog: catalog,
      now: now,
      tasteProfile: fatigueProfile,
    );

    expect(fatigueMatches.first.recipe.id, 'shakshuka');
    expect(
      fatigueProfile.recipeFatigue(
        recipe: omelet,
        canonicalizer: RecipeIngredientCanonicalizer(catalog),
      ),
      greaterThan(
        fatigueProfile.recipeFatigue(
          recipe: shakshuka,
          canonicalizer: RecipeIngredientCanonicalizer(catalog),
        ),
      ),
    );
  });

  test('forbidden pairing ranks below neutral recipe with same coverage', () {
    final neutral = Recipe(
      id: 'neutral',
      title: 'Овсянка с яблоком',
      timeMin: 8,
      tags: const ['breakfast'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Овсяные хлопья', amount: 60, unit: Unit.g),
        RecipeIngredient(name: 'Яблоко', amount: 1, unit: Unit.pcs),
      ],
      steps: const ['Свари овсянку', 'Добавь яблоко и подай'],
    );
    final forbidden = Recipe(
      id: 'forbidden',
      title: 'Сахар с тунцом',
      timeMin: 4,
      tags: const ['quick'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Тунец', amount: 100, unit: Unit.g),
        RecipeIngredient(name: 'Сахар', amount: 10, unit: Unit.g),
      ],
      steps: const ['Смешай', 'Подавай'],
    );

    final matches = rankBestRecipes(
      recipes: [forbidden, neutral],
      fridgeItems: const [
        FridgeItem(id: 'f1', name: 'Тунец', amount: 200, unit: Unit.g),
        FridgeItem(id: 'f2', name: 'Сахар', amount: 200, unit: Unit.g),
        FridgeItem(id: 'f3', name: 'Овсяные хлопья', amount: 400, unit: Unit.g),
        FridgeItem(id: 'f4', name: 'Яблоко', amount: 2, unit: Unit.pcs),
      ],
      shelfItems: const [],
      catalog: catalog,
    );

    expect(matches.first.recipe.id, 'neutral');
    expect(matches.last.recipe.id, 'forbidden');
    expect(matches.first.pairingScore, greaterThan(matches.last.pairingScore));
  });

  test('flavor-balanced pasta ranks above dry pasta with same pantry access',
      () {
    final balanced = Recipe(
      id: 'balanced_pasta',
      title: 'Паста с сыром и томатами',
      timeMin: 14,
      tags: const ['quick'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Макароны', amount: 100, unit: Unit.g),
        RecipeIngredient(name: 'Сыр', amount: 40, unit: Unit.g),
        RecipeIngredient(name: 'Помидор', amount: 150, unit: Unit.g),
      ],
      steps: const ['Отвари', 'Смешай', 'Подавай'],
    );
    final dry = Recipe(
      id: 'dry_pasta',
      title: 'Простая паста',
      timeMin: 10,
      tags: const ['quick'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Макароны', amount: 100, unit: Unit.g),
      ],
      steps: const ['Отвари', 'Подавай'],
    );

    final matches = rankBestRecipes(
      recipes: [dry, balanced],
      fridgeItems: const [
        FridgeItem(id: 'f1', name: 'Макароны', amount: 300, unit: Unit.g),
        FridgeItem(id: 'f2', name: 'Сыр', amount: 120, unit: Unit.g),
        FridgeItem(id: 'f3', name: 'Помидоры', amount: 300, unit: Unit.g),
      ],
      shelfItems: const [
        ShelfItem(id: 's1', name: 'Оливковое масло', inStock: true),
        ShelfItem(id: 's2', name: 'Соль', inStock: true),
      ],
      catalog: catalog,
    );

    expect(matches.first.recipe.id, 'balanced_pasta');
    expect(matches.first.flavorScore, greaterThan(matches.last.flavorScore));
  });

  test('properly finished pasta outranks same ingredients with weak technique',
      () {
    final proper = Recipe(
      id: 'proper_finish',
      title: 'Паста с сыром и томатами',
      timeMin: 14,
      tags: const ['quick'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Макароны', amount: 100, unit: Unit.g),
        RecipeIngredient(name: 'Сыр', amount: 40, unit: Unit.g),
        RecipeIngredient(name: 'Помидор', amount: 150, unit: Unit.g),
      ],
      steps: const [
        'Отвари макароны до готовности.',
        'Смешай с томатами, сыром и маслом до единого вкуса.',
        'Подавай сразу.',
      ],
    );
    final weak = Recipe(
      id: 'weak_finish',
      title: 'Паста с сыром и томатами',
      timeMin: 14,
      tags: const ['quick'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Макароны', amount: 100, unit: Unit.g),
        RecipeIngredient(name: 'Сыр', amount: 40, unit: Unit.g),
        RecipeIngredient(name: 'Помидор', amount: 150, unit: Unit.g),
      ],
      steps: const [
        'Отвари макароны.',
        'Нарежь томаты и сыр.',
        'Разложи рядом и подай.',
      ],
    );

    final matches = rankBestRecipes(
      recipes: [weak, proper],
      fridgeItems: const [
        FridgeItem(id: 'f1', name: 'Макароны', amount: 300, unit: Unit.g),
        FridgeItem(id: 'f2', name: 'Сыр', amount: 120, unit: Unit.g),
        FridgeItem(id: 'f3', name: 'Помидоры', amount: 300, unit: Unit.g),
      ],
      shelfItems: const [
        ShelfItem(id: 's1', name: 'Оливковое масло', inStock: true),
        ShelfItem(id: 's2', name: 'Соль', inStock: true),
      ],
      catalog: catalog,
    );

    expect(matches.first.recipe.id, 'proper_finish');
    expect(
        matches.first.techniqueScore, greaterThan(matches.last.techniqueScore));
  });

  test(
      'baked fish with better oven technique outranks weak version with same ingredients',
      () {
    final strong = Recipe(
      id: 'strong_fish',
      title: 'Рыба с картофелем и лимоном',
      timeMin: 38,
      tags: const ['bake'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Рыба', amount: 300, unit: Unit.g),
        RecipeIngredient(name: 'Картофель', amount: 400, unit: Unit.g),
        RecipeIngredient(name: 'Лимон', amount: 1, unit: Unit.pcs),
      ],
      steps: const [
        'Сбрызни рыбу лимоном.',
        'Накрой форму и запекай до готовности.',
        'Открой, дай слегка подрумяниться и подай.',
      ],
    );
    final weak = Recipe(
      id: 'weak_fish',
      title: 'Рыба с картофелем и лимоном',
      timeMin: 34,
      tags: const ['bake'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Рыба', amount: 300, unit: Unit.g),
        RecipeIngredient(name: 'Картофель', amount: 400, unit: Unit.g),
        RecipeIngredient(name: 'Лимон', amount: 1, unit: Unit.pcs),
      ],
      steps: const [
        'Выложи в форму.',
        'Запекай и подай.',
      ],
    );

    final matches = rankBestRecipes(
      recipes: [weak, strong],
      fridgeItems: const [
        FridgeItem(id: 'f1', name: 'Рыба', amount: 600, unit: Unit.g),
        FridgeItem(id: 'f2', name: 'Картофель', amount: 900, unit: Unit.g),
        FridgeItem(id: 'f3', name: 'Лимон', amount: 2, unit: Unit.pcs),
      ],
      shelfItems: const [
        ShelfItem(id: 's1', name: 'Соль', inStock: true),
        ShelfItem(id: 's2', name: 'Перец', inStock: true),
        ShelfItem(id: 's3', name: 'Масло', inStock: true),
      ],
      catalog: catalog,
    );

    expect(matches.first.recipe.id, 'strong_fish');
    expect(
        matches.first.techniqueScore, greaterThan(matches.last.techniqueScore));
    expect(matches.first.score, greaterThan(matches.last.score));
  });

  test('crunchy herby salad outranks soft salad with similar speed', () {
    final lively = Recipe(
      id: 'lively_salad',
      title: 'Салат из капусты с яблоком',
      timeMin: 10,
      tags: const ['quick', 'no_oven', 'healthy'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Капуста', amount: 180, unit: Unit.g),
        RecipeIngredient(name: 'Яблоко', amount: 120, unit: Unit.g),
        RecipeIngredient(name: 'Йогурт', amount: 80, unit: Unit.g),
        RecipeIngredient(
          name: 'Укроп',
          amount: 8,
          unit: Unit.g,
          required: false,
        ),
      ],
      steps: const [
        'Нашинкуй капусту.',
        'Смешай с яблоком.',
        'Заправь йогуртом и укропом перед подачей.',
      ],
    );
    final soft = Recipe(
      id: 'soft_salad',
      title: 'Мягкий салат из помидора и сыра',
      timeMin: 8,
      tags: const ['quick', 'no_oven'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Помидор', amount: 160, unit: Unit.g),
        RecipeIngredient(name: 'Сыр', amount: 50, unit: Unit.g),
      ],
      steps: const [
        'Нарежь помидор.',
        'Смешай с сыром и подай.',
      ],
    );

    final matches = rankBestRecipes(
      recipes: [soft, lively],
      fridgeItems: const [
        FridgeItem(id: 'f1', name: 'Капуста', amount: 400, unit: Unit.g),
        FridgeItem(id: 'f2', name: 'Яблоко', amount: 2, unit: Unit.pcs),
        FridgeItem(id: 'f3', name: 'Йогурт', amount: 250, unit: Unit.g),
        FridgeItem(id: 'f4', name: 'Укроп', amount: 30, unit: Unit.g),
        FridgeItem(id: 'f5', name: 'Помидоры', amount: 250, unit: Unit.g),
        FridgeItem(id: 'f6', name: 'Сыр', amount: 120, unit: Unit.g),
      ],
      shelfItems: const [
        ShelfItem(id: 's1', name: 'Соль', inStock: true),
      ],
      catalog: catalog,
    );

    expect(matches.first.recipe.id, 'lively_salad');
    expect(matches.first.flavorScore, greaterThan(matches.last.flavorScore));
  });

  test('pantry blend support improves meat recipe without faking ingredients',
      () {
    final recipe = Recipe(
      id: 'beef_with_onion',
      title: 'Говядина с луком',
      timeMin: 28,
      tags: const ['one_pan', 'stew'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Говядина', amount: 320, unit: Unit.g),
        RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
      ],
      steps: const [
        'Нарежь лук.',
        'Обжарь говядину с луком и доведи до мягкости.',
        'Подавай горячей.',
      ],
    );

    final withoutBlend = rankBestRecipes(
      recipes: [recipe],
      fridgeItems: const [
        FridgeItem(id: 'f1', name: 'Говядина', amount: 700, unit: Unit.g),
        FridgeItem(id: 'f2', name: 'Лук', amount: 2, unit: Unit.pcs),
      ],
      shelfItems: const [],
      catalog: catalog,
    ).single;

    final withBlend = rankBestRecipes(
      recipes: [recipe],
      fridgeItems: const [
        FridgeItem(id: 'f1', name: 'Говядина', amount: 700, unit: Unit.g),
        FridgeItem(id: 'f2', name: 'Лук', amount: 2, unit: Unit.pcs),
      ],
      shelfItems: const [
        ShelfItem(
          id: 's1',
          name: 'Хмели-сунели',
          inStock: true,
          canonicalName: 'хмели сунели',
          category: 'blend',
          supportCanonicals: ['тёплая специя', 'травяной акцент'],
          isBlend: true,
        ),
      ],
      catalog: catalog,
    ).single;

    expect(withBlend.flavorScore, greaterThan(withoutBlend.flavorScore));
    expect(withBlend.score, greaterThan(withoutBlend.score));
    expect(
      withBlend.seasoningScore,
      greaterThanOrEqualTo(withoutBlend.seasoningScore),
    );
  });

  test('balanced stew ranks above heavy stew with no bright finish', () {
    final heavy = Recipe(
      id: 'heavy_stew',
      title: 'Говядина со сметаной',
      timeMin: 35,
      tags: const ['stew'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Говядина', amount: 300, unit: Unit.g),
        RecipeIngredient(name: 'Картофель', amount: 250, unit: Unit.g),
        RecipeIngredient(name: 'Сметана', amount: 80, unit: Unit.g),
      ],
      steps: const [
        'Обжарь говядину.',
        'Добавь картофель и сметану.',
        'Туши до мягкости и подавай.',
      ],
    );

    final balanced = Recipe(
      id: 'balanced_stew',
      title: 'Говядина с грибами, лимоном и укропом',
      timeMin: 35,
      tags: const ['stew'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Говядина', amount: 300, unit: Unit.g),
        RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
        RecipeIngredient(name: 'Грибы', amount: 180, unit: Unit.g),
        RecipeIngredient(name: 'Сметана', amount: 80, unit: Unit.g),
        RecipeIngredient(name: 'Паприка', amount: 6, unit: Unit.g),
        RecipeIngredient(name: 'Лимон', amount: 30, unit: Unit.g),
        RecipeIngredient(name: 'Укроп', amount: 10, unit: Unit.g),
      ],
      steps: const [
        'Обжарь говядину с луком и грибами.',
        'Добавь паприку и сметану, затем туши до мягкости.',
        'В конце добавь лимон и укроп, затем подавай.',
      ],
    );

    final matches = rankBestRecipes(
      recipes: [heavy, balanced],
      fridgeItems: const [
        FridgeItem(id: 'f1', name: 'Говядина', amount: 800, unit: Unit.g),
        FridgeItem(id: 'f2', name: 'Картофель', amount: 1000, unit: Unit.g),
        FridgeItem(id: 'f3', name: 'Сметана', amount: 250, unit: Unit.g),
        FridgeItem(id: 'f4', name: 'Лимон', amount: 120, unit: Unit.g),
        FridgeItem(id: 'f5', name: 'Укроп', amount: 40, unit: Unit.g),
        FridgeItem(id: 'f6', name: 'Лук', amount: 3, unit: Unit.pcs),
        FridgeItem(id: 'f7', name: 'Грибы', amount: 300, unit: Unit.g),
        FridgeItem(id: 'f8', name: 'Паприка', amount: 50, unit: Unit.g),
      ],
      shelfItems: const [
        ShelfItem(id: 's1', name: 'Соль', inStock: true),
        ShelfItem(id: 's2', name: 'Перец', inStock: true),
      ],
      catalog: catalog,
    );

    expect(matches.first.recipe.id, 'balanced_stew');
    expect(matches.first.flavorScore, greaterThan(matches.last.flavorScore));
    expect(matches.first.score, greaterThan(matches.last.score));
  });

  test('protected baked meat ranks above dry oven version', () {
    final dryBake = Recipe(
      id: 'dry_bake',
      title: 'Свинина с картофелем',
      timeMin: 42,
      tags: const ['bake'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Свинина', amount: 320, unit: Unit.g),
        RecipeIngredient(name: 'Картофель', amount: 400, unit: Unit.g),
        RecipeIngredient(name: 'Паприка', amount: 6, unit: Unit.g),
      ],
      steps: const [
        'Выложи мясо и картофель в форму.',
        'Запекай до готовности и сразу подавай.',
      ],
    );

    final protectedBake = Recipe(
      id: 'protected_bake',
      title: 'Свинина с картофелем под сметаной',
      timeMin: 45,
      tags: const ['bake'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Свинина', amount: 320, unit: Unit.g),
        RecipeIngredient(name: 'Картофель', amount: 400, unit: Unit.g),
        RecipeIngredient(name: 'Паприка', amount: 6, unit: Unit.g),
        RecipeIngredient(name: 'Сметана', amount: 80, unit: Unit.g),
      ],
      steps: const [
        'Замаринуй мясо со сметаной и паприкой.',
        'Накрой форму и запекай до готовности.',
        'Дай мясу отдохнуть пару минут и подавай.',
      ],
    );

    final matches = rankBestRecipes(
      recipes: [dryBake, protectedBake],
      fridgeItems: const [
        FridgeItem(id: 'f1', name: 'Свинина', amount: 800, unit: Unit.g),
        FridgeItem(id: 'f2', name: 'Картофель', amount: 1200, unit: Unit.g),
        FridgeItem(id: 'f3', name: 'Паприка', amount: 50, unit: Unit.g),
        FridgeItem(id: 'f4', name: 'Сметана', amount: 250, unit: Unit.g),
      ],
      shelfItems: const [
        ShelfItem(id: 's1', name: 'Соль', inStock: true),
        ShelfItem(id: 's2', name: 'Перец', inStock: true),
      ],
      catalog: catalog,
    );

    expect(matches.first.recipe.id, 'protected_bake');
    expect(
        matches.first.techniqueScore, greaterThan(matches.last.techniqueScore));
    expect(matches.first.score, greaterThan(matches.last.score));
  });
}

List<ProductCatalogEntry> _loadCatalog() {
  final jsonText = File('assets/products/catalog_ru.json').readAsStringSync();
  final raw = jsonDecode(jsonText) as List<dynamic>;
  return raw
      .map((entry) =>
          ProductCatalogEntry.fromJson(entry as Map<String, dynamic>))
      .toList();
}

List<Recipe> _loadRecipes() {
  final jsonText = File('assets/recipes/recipes.json').readAsStringSync();
  final raw = jsonDecode(jsonText) as List<dynamic>;
  return raw
      .map((entry) => Recipe.fromJson(entry as Map<String, dynamic>))
      .toList();
}
