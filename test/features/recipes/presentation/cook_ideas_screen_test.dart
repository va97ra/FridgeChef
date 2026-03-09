import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/fridge/domain/product_catalog_entry.dart';
import 'package:help_to_cook/features/recipes/data/generated_recipe_draft_parser.dart';
import 'package:help_to_cook/features/recipes/data/user_recipes_repo.dart';
import 'package:help_to_cook/features/recipes/domain/recipe.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_ingredient.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_match.dart';
import 'package:help_to_cook/features/recipes/presentation/cook_ideas_screen.dart';
import 'package:help_to_cook/features/recipes/presentation/providers.dart';
import 'package:help_to_cook/features/shelf/domain/pantry_catalog_entry.dart';

void main() {
  testWidgets('shows hero block and separate offline ideas section',
      (tester) async {
    final semantics = tester.ensureSemantics();

    final bestRecipe = Recipe(
      id: 'best',
      title: 'Шакшука',
      timeMin: 18,
      tags: const ['one_pan'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Яйцо', amount: 4, unit: Unit.pcs),
      ],
      steps: const ['Шаг 1', 'Шаг 2'],
    );
    final secondRecipe = Recipe(
      id: 'second',
      title: 'Омлет',
      timeMin: 10,
      tags: const ['quick'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Яйцо', amount: 2, unit: Unit.pcs),
      ],
      steps: const ['Шаг 1'],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recipesProvider
              .overrideWith((ref) async => [bestRecipe, secondRecipe]),
          productCatalogProvider.overrideWith(
            (ref) async => const [
              ProductCatalogEntry(
                id: 'egg',
                name: 'Яйца',
                synonyms: ['яйцо', 'яйца'],
                defaultUnit: Unit.pcs,
              ),
            ],
          ),
          recipeMatchesProvider.overrideWith(
            (ref) => [
              RecipeMatch(
                recipe: bestRecipe,
                source: RecipeMatchSource.generated,
                score: 0.94,
                why: const [
                  'все продукты есть дома',
                  'сильное сочетание яйцо + помидор'
                ],
                missingIngredients: const [],
                matchedCount: 3,
                totalCount: 3,
                matchedRequired: 3,
                totalRequired: 3,
                matchedOptional: 0,
                totalOptional: 0,
              ),
              RecipeMatch(
                recipe: secondRecipe,
                score: 0.78,
                why: const ['готовится быстро'],
                missingIngredients: const [],
                matchedCount: 2,
                totalCount: 2,
                matchedRequired: 2,
                totalRequired: 2,
                matchedOptional: 0,
                totalOptional: 0,
              ),
            ],
          ),
        ],
        child: const MaterialApp(
          home: CookIdeasScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Лучшее блюдо сегодня'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Открыть лучший рецепт Шакшука')),
      findsOneWidget,
    );
    expect(find.text('Шеф-идея'), findsWidgets);
    expect(find.text('все продукты есть дома'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Шеф предлагает'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Шеф предлагает'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Открыть рецепт Омлет')),
      findsOneWidget,
    );

    semantics.dispose();
  });

  testWidgets('renames and deletes saved recipe from cook ideas actions',
      (tester) async {
    final baseRecipe = Recipe(
      id: 'base',
      title: 'Шакшука',
      timeMin: 18,
      tags: const ['one_pan'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Яйцо', amount: 4, unit: Unit.pcs),
      ],
      steps: const ['Шаг 1', 'Шаг 2'],
    );
    final savedRecipe = Recipe(
      id: 'saved_1',
      title: 'Шеф-омлет',
      timeMin: 10,
      tags: const ['quick', 'generated_local'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Яйцо', amount: 2, unit: Unit.pcs),
      ],
      steps: const ['Шаг 1'],
      source: RecipeSource.generatedSaved,
      isUserEditable: true,
    );
    final repo = _FakeUserRecipesRepo([savedRecipe]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userRecipesRepoProvider.overrideWithValue(repo),
          recipesProvider.overrideWith(
            (ref) async => [baseRecipe, ...await repo.getAllUserRecipes()],
          ),
          productCatalogProvider.overrideWith(
            (ref) async => const [
              ProductCatalogEntry(
                id: 'egg',
                name: 'Яйца',
                synonyms: ['яйцо', 'яйца'],
                defaultUnit: Unit.pcs,
              ),
            ],
          ),
          pantryCatalogProvider.overrideWith(
            (ref) async => const [
              PantryCatalogEntry(
                id: 'salt',
                name: 'Соль',
                canonicalName: 'соль',
                aliases: ['соль'],
                category: 'basic',
                isStarter: true,
              ),
            ],
          ),
          recipeMatchesProvider.overrideWith((ref) {
            final recipes = ref.watch(recipesProvider).valueOrNull ?? const <Recipe>[];
            return recipes.map((recipe) {
              final isSaved = recipe.id == savedRecipe.id;
              return RecipeMatch(
                recipe: recipe,
                source: isSaved ? RecipeMatchSource.base : RecipeMatchSource.generated,
                score: isSaved ? 0.78 : 0.94,
                why: isSaved
                    ? const ['сохранённый вариант под рукой']
                    : const ['все продукты есть дома'],
                missingIngredients: const [],
                matchedCount: recipe.ingredients.length,
                totalCount: recipe.ingredients.length,
                matchedRequired: recipe.ingredients.length,
                totalRequired: recipe.ingredients.length,
                matchedOptional: 0,
                totalOptional: 0,
              );
            }).toList();
          }),
        ],
        child: const MaterialApp(
          home: CookIdeasScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byTooltip('Действия рецепта Шеф-омлет'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Действия рецепта Шеф-омлет'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Переименовать'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'Омлет шефа');
    await tester.tap(find.text('Сохранить').last);
    await tester.pumpAndSettle();

    expect(repo.recipes.single.title, 'Омлет шефа');
    await tester.scrollUntilVisible(
      find.byTooltip('Действия рецепта Омлет шефа'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Омлет шефа'), findsOneWidget);

    await tester.tap(find.byTooltip('Действия рецепта Омлет шефа'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить').last);
    await tester.pumpAndSettle();

    expect(repo.recipes, isEmpty);
    expect(find.text('Омлет шефа', skipOffstage: false), findsNothing);
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
}
