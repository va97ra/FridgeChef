import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/recipes/domain/recipe.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_ingredient.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_match.dart';
import 'package:help_to_cook/features/recipes/presentation/widgets/recipe_card.dart';

void main() {
  testWidgets('shows saved recipe badge and actions menu for editable recipe',
      (tester) async {
    final match = _buildMatch(
      recipe: Recipe(
        id: 'ai_1',
        title: 'AI Омлет',
        timeMin: 12,
        tags: const ['breakfast', 'quick'],
        servingsBase: 2,
        ingredients: const [
          RecipeIngredient(name: 'Яйцо', amount: 2, unit: Unit.pcs),
        ],
        steps: const ['Пожарить'],
        source: RecipeSource.generatedSaved,
        isUserEditable: true,
      ),
      why: const ['все продукты есть дома'],
      source: RecipeMatchSource.generated,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecipeCard(
            match: match,
            onTap: () {},
            onRename: () {},
            onDelete: () {},
          ),
        ),
      ),
    );

    expect(find.text('Шеф-идея'), findsOneWidget);
    expect(find.text('Завтрак'), findsOneWidget);
    expect(find.text('Легко'), findsOneWidget);
    expect(find.text('все продукты есть дома'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
  });

  testWidgets('shows base source and hides actions menu for asset recipes',
      (tester) async {
    final match = _buildMatch(
      recipe: Recipe(
        id: 'asset_1',
        title: 'Суп',
        timeMin: 30,
        tags: const ['one_pan'],
        servingsBase: 2,
        ingredients: const [
          RecipeIngredient(name: 'Курица', amount: 300, unit: Unit.g),
          RecipeIngredient(name: 'Рис', amount: 100, unit: Unit.g),
        ],
        steps: const ['Кипятить'],
      ),
      why: const ['готовится быстро'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecipeCard(
            match: match,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.more_vert_rounded), findsNothing);
    expect(find.text('База'), findsOneWidget);
    expect(find.text('Сытно'), findsOneWidget);
    expect(find.text('Ужин'), findsOneWidget);
    expect(find.text('готовится быстро'), findsOneWidget);
  });
}

RecipeMatch _buildMatch({
  required Recipe recipe,
  RecipeMatchSource source = RecipeMatchSource.base,
  List<String> why = const [],
}) {
  return RecipeMatch(
    recipe: recipe,
    source: source,
    score: 0.9,
    why: why,
    missingIngredients: const [],
    matchedCount: recipe.ingredients.length,
    totalCount: recipe.ingredients.length,
    matchedRequired: recipe.ingredients.length,
    totalRequired: recipe.ingredients.length,
    matchedOptional: 0,
    totalOptional: 0,
  );
}
