import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/theme/app_theme.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/fridge/domain/product_catalog_entry.dart';
import 'package:help_to_cook/features/recipes/data/generated_recipe_draft_parser.dart';
import 'package:help_to_cook/features/recipes/data/recipe_interaction_history_repo.dart';
import 'package:help_to_cook/features/recipes/data/user_recipes_repo.dart';
import 'package:help_to_cook/features/recipes/domain/recipe.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_ingredient.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_interaction_event.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_nutrition.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_nutrition_estimator.dart';
import 'package:help_to_cook/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:help_to_cook/features/recipes/presentation/providers.dart';

void main() {
  testWidgets('shows description card when recipe has description',
      (tester) async {
    final recipe = Recipe(
      id: 'r1',
      title: 'Сырники',
      description:
          'Нежные сырники с румяной корочкой, которые хорошо подходят для завтрака.',
      timeMin: 20,
      tags: const ['breakfast', 'quick'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Творог', amount: 250, unit: Unit.g),
      ],
      steps: const ['Смешать', 'Обжарьте с двух сторон до румяной корочки'],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: RecipeDetailScreen(recipe: recipe),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('О блюде'), findsOneWidget);
    expect(find.textContaining('Нежные сырники'), findsOneWidget);
    expect(find.text('Завтрак'), findsOneWidget);
    expect(find.text('Легко'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byIcon(Icons.tips_and_updates_rounded),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Жарь до золотистой корочки'), findsOneWidget);
  });

  testWidgets('shows save action and chef context for generated draft recipe',
      (tester) async {
    final recipe = Recipe(
      id: 'generated_1',
      title: 'Шеф-сковорода',
      description: 'Офлайн-рецепт от локального шефа.',
      timeMin: 12,
      tags: const ['quick', 'generated_local'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Яйца', amount: 3, unit: Unit.pcs),
      ],
      steps: const ['Шаг 1', 'Шаг 2'],
      source: RecipeSource.generatedDraft,
      anchorIngredients: const ['Яйца'],
      implicitPantryItems: const ['Соль'],
      chefProfile: 'skillet',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: RecipeDetailScreen(recipe: recipe),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Сохранить в мои рецепты'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Сохранить в мои рецепты'), findsOneWidget);
    expect(find.text('Что учёл шеф'), findsOneWidget);
    expect(find.text('В основе'), findsOneWidget);
    expect(find.text('Яйца'), findsWidgets);
    expect(find.text('Базовые мелочи'), findsOneWidget);
    expect(find.text('Соль'), findsOneWidget);
  });

  testWidgets('shows nutrition estimate and updates it for servings',
      (tester) async {
    final recipe = Recipe(
      id: 'nutrition_recipe',
      title: 'Омлет',
      timeMin: 10,
      tags: const ['quick'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Яйца', amount: 2, unit: Unit.pcs),
        RecipeIngredient(name: 'Молоко', amount: 100, unit: Unit.ml),
      ],
      steps: const ['Смешать', 'Пожарить'],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recipeNutritionEstimatorProvider.overrideWith(
            (ref) => _buildNutritionEstimator(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: RecipeDetailScreen(recipe: recipe),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Пищевая ценность'), findsOneWidget);
    expect(find.text('~208'), findsOneWidget);
    expect(find.text('15 г'), findsOneWidget);
    expect(find.text('13 г'), findsOneWidget);
    expect(find.text('5.9 г'), findsOneWidget);
    expect(
        find.textContaining('Оценка по 2 из 2 ингредиентов'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, '4'));
    await tester.pumpAndSettle();

    expect(find.text('~416'), findsOneWidget);
    expect(find.text('31 г'), findsOneWidget);
    expect(find.text('26 г'), findsOneWidget);
    expect(find.text('12 г'), findsOneWidget);
  });

  testWidgets('exposes recipe steps through semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    final recipe = Recipe(
      id: 'r2',
      title: 'Омлет',
      timeMin: 10,
      tags: const ['quick'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Яйца', amount: 2, unit: Unit.pcs),
      ],
      steps: const ['Взбей яйца', 'Обжарь на сковороде'],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: RecipeDetailScreen(recipe: recipe),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Шаг 1'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.text('Шаг 1')),
      matchesSemantics(
        label: 'Отметить шаг 1 выполненным. Взбей яйца',
        isButton: true,
        hasTapAction: true,
      ),
    );

    await tester.tap(find.text('Шаг 1'));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.text('Шаг 1')),
      matchesSemantics(
        label: 'Шаг 1 выполнен. Взбей яйца',
        isButton: true,
        hasTapAction: true,
      ),
    );

    semantics.dispose();
  });

  testWidgets('renames and deletes saved recipe from detail screen',
      (tester) async {
    final recipe = Recipe(
      id: 'saved_recipe',
      title: 'Шеф-омлет',
      timeMin: 10,
      tags: const ['quick', 'generated_local'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Яйца', amount: 2, unit: Unit.pcs),
      ],
      steps: const ['Взбей яйца', 'Обжарь на сковороде'],
      source: RecipeSource.generatedSaved,
      isUserEditable: true,
    );
    final repo = _FakeUserRecipesRepo([recipe]);
    final interactionRepo = _FakeRecipeInteractionHistoryRepo();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userRecipesRepoProvider.overrideWithValue(repo),
          recipeInteractionHistoryRepoProvider.overrideWithValue(
            interactionRepo,
          ),
          recipesProvider.overrideWith(
            (ref) async => await repo.getAllUserRecipes(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RecipeDetailScreen(recipe: recipe),
                      ),
                    ),
                    child: const Text('Открыть рецепт'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Открыть рецепт'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Действия рецепта'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Переименовать'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'Омлет шефа');
    await tester.tap(find.text('Сохранить').last);
    await tester.pumpAndSettle();

    expect(repo.recipes.single.title, 'Омлет шефа');
    expect(find.text('Омлет шефа'), findsWidgets);
    expect(
      interactionRepo.events.any(
        (event) => event.type == RecipeInteractionType.renamed,
      ),
      isTrue,
    );

    await tester.tap(find.byTooltip('Действия рецепта'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить').last);
    await tester.pumpAndSettle();

    expect(repo.recipes, isEmpty);
    expect(find.text('Открыть рецепт'), findsOneWidget);
    expect(
      interactionRepo.events.any(
        (event) => event.type == RecipeInteractionType.deleted,
      ),
      isTrue,
    );
  });

  testWidgets('records recook memory when all recipe steps are completed',
      (tester) async {
    final recipe = Recipe(
      id: 'recook_recipe',
      title: 'Омлет',
      timeMin: 10,
      tags: const ['quick'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Яйца', amount: 2, unit: Unit.pcs),
      ],
      steps: const ['Взбей яйца', 'Обжарь на сковороде'],
    );
    final interactionRepo = _FakeRecipeInteractionHistoryRepo();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recipeInteractionHistoryRepoProvider.overrideWithValue(
            interactionRepo,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: RecipeDetailScreen(recipe: recipe),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Шаг 1'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Шаг 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Шаг 2'));
    await tester.pumpAndSettle();

    expect(
      interactionRepo.events.where(
        (event) => event.type == RecipeInteractionType.recooked,
      ),
      hasLength(1),
    );
    expect(
      find.text('Шеф запомнил, что ты приготовил это блюдо'),
      findsOneWidget,
    );
  });

  testWidgets('saving generated recipe records save interaction',
      (tester) async {
    final recipe = Recipe(
      id: 'generated_recipe',
      title: 'Шеф-идея',
      timeMin: 12,
      tags: const ['generated_local', 'quick'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Яйца', amount: 3, unit: Unit.pcs),
      ],
      steps: const ['Взбей', 'Пожарь'],
      source: RecipeSource.generatedDraft,
      anchorIngredients: const ['Яйца'],
    );
    final repo = _FakeUserRecipesRepo([]);
    final interactionRepo = _FakeRecipeInteractionHistoryRepo();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userRecipesRepoProvider.overrideWithValue(repo),
          recipeInteractionHistoryRepoProvider.overrideWithValue(
            interactionRepo,
          ),
          recipesProvider.overrideWith(
            (ref) async => await repo.getAllUserRecipes(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: RecipeDetailScreen(recipe: recipe),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Сохранить в мои рецепты'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сохранить в мои рецепты'));
    await tester.pumpAndSettle();

    expect(repo.recipes, hasLength(1));
    expect(repo.recipes.single.source, RecipeSource.generatedSaved);
    expect(
      interactionRepo.events.where(
        (event) => event.type == RecipeInteractionType.saved,
      ),
      hasLength(1),
    );
  });
}

class _FakeUserRecipesRepo extends UserRecipesRepo {
  _FakeUserRecipesRepo(List<Recipe> initialRecipes)
      : recipes = List<Recipe>.from(initialRecipes),
        super(
          boxName: 'test',
          parser: const GeneratedRecipeDraftParser(),
        );

  final List<Recipe> recipes;

  @override
  Future<List<Recipe>> getAllUserRecipes() async {
    return List<Recipe>.from(recipes);
  }

  @override
  Future<void> renameUserRecipe(String id, String newTitle) async {
    final index = recipes.indexWhere((recipe) => recipe.id == id);
    if (index == -1) {
      return;
    }
    recipes[index] = recipes[index].copyWith(
      title: newTitle.trim(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteUserRecipe(String id) async {
    recipes.removeWhere((recipe) => recipe.id == id);
  }

  @override
  Future<List<Recipe>> findPotentialDuplicatesForRecipe(Recipe recipe) async {
    return const [];
  }

  @override
  Future<SaveResult> saveGeneratedRecipe({
    required Recipe recipe,
    required SaveMode mode,
  }) async {
    final savedRecipe = recipe.copyWith(
      id: 'saved_${recipe.id}',
      source: RecipeSource.generatedSaved,
      isUserEditable: true,
      createdAt: DateTime(2026, 3, 9, 12),
      updatedAt: DateTime(2026, 3, 9, 12),
    );
    recipes.add(savedRecipe);
    return SaveResult(
      recipe: savedRecipe,
      action: SaveAction.created,
      duplicates: const [],
    );
  }
}

class _FakeRecipeInteractionHistoryRepo extends RecipeInteractionHistoryRepo {
  final List<RecipeInteractionEvent> events = [];

  @override
  Future<List<RecipeInteractionEvent>> loadAll() async {
    return List<RecipeInteractionEvent>.from(events);
  }

  @override
  Future<void> record({
    required RecipeInteractionType type,
    required Recipe recipe,
    DateTime? occurredAt,
  }) async {
    events.insert(
      0,
      RecipeInteractionEvent(
        type: type,
        recipeSnapshot: recipe,
        occurredAt: occurredAt ?? DateTime(2026, 3, 9, 12),
      ),
    );
  }

  @override
  Future<void> recordMany({
    required RecipeInteractionType type,
    required Iterable<Recipe> recipes,
    DateTime? occurredAt,
  }) async {
    final timestamp = occurredAt ?? DateTime(2026, 3, 9, 12);
    for (final recipe in recipes.toList().reversed) {
      events.insert(
        0,
        RecipeInteractionEvent(
          type: type,
          recipeSnapshot: recipe,
          occurredAt: timestamp,
        ),
      );
    }
  }
}

RecipeNutritionEstimator _buildNutritionEstimator() {
  return RecipeNutritionEstimator(
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
}
