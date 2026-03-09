import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/recipes/data/generated_recipe_draft_parser.dart';
import 'package:help_to_cook/features/recipes/data/user_recipes_repo.dart';
import 'package:help_to_cook/features/recipes/domain/recipe.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_ingredient.dart';
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
          home: RecipeDetailScreen(recipe: recipe),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Сохранить в мои рецепты'), findsOneWidget);
    expect(find.text('Что учёл шеф'), findsOneWidget);
    expect(find.text('В основе'), findsOneWidget);
    expect(find.text('Яйца'), findsWidgets);
    expect(find.text('Базовые мелочи'), findsOneWidget);
    expect(find.text('Соль'), findsOneWidget);
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userRecipesRepoProvider.overrideWithValue(repo),
          recipesProvider.overrideWith(
            (ref) async => await repo.getAllUserRecipes(),
          ),
        ],
        child: MaterialApp(
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

    await tester.tap(find.byTooltip('Действия рецепта'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить').last);
    await tester.pumpAndSettle();

    expect(repo.recipes, isEmpty);
    expect(find.text('Открыть рецепт'), findsOneWidget);
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
