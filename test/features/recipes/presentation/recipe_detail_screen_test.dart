import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/recipes/domain/recipe.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_ingredient.dart';
import 'package:help_to_cook/features/recipes/presentation/recipe_detail_screen.dart';

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
}
