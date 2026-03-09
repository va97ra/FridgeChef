import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/fridge/domain/product_catalog_entry.dart';
import 'package:help_to_cook/features/recipes/domain/recipe.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_ingredient.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_match.dart';
import 'package:help_to_cook/features/recipes/presentation/cook_ideas_screen.dart';
import 'package:help_to_cook/features/recipes/presentation/providers.dart';

void main() {
  testWidgets('shows hero block and separate offline ideas section',
      (tester) async {
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
          recipesProvider.overrideWith((ref) async => [bestRecipe, secondRecipe]),
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
                why: const ['все продукты есть дома', 'сильное сочетание яйцо + помидор'],
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
    expect(find.text('Шеф-идея'), findsWidgets);
    expect(find.text('все продукты есть дома'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Шеф предлагает'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Шеф предлагает'), findsOneWidget);
  });
}
