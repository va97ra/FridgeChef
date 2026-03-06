import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/recipes/domain/recipe.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_ingredient.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_match.dart';
import 'package:help_to_cook/features/recipes/presentation/widgets/recipe_card.dart';

void main() {
  testWidgets('shows AI badge and actions menu for editable AI recipes',
      (tester) async {
    final match = _buildMatch(
      recipe: Recipe(
        id: 'ai_1',
        title: 'AI Омлет',
        timeMin: 12,
        tags: const ['быстро'],
        servingsBase: 2,
        ingredients: const [
          RecipeIngredient(name: 'Яйцо', amount: 2, unit: Unit.pcs),
        ],
        steps: const ['Пожарить'],
        source: RecipeSource.aiSaved,
        isUserEditable: true,
      ),
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

    expect(find.text('AI'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
  });

  testWidgets('hides actions menu for asset recipes', (tester) async {
    final match = _buildMatch(
      recipe: Recipe(
        id: 'asset_1',
        title: 'Суп',
        timeMin: 30,
        tags: const ['домашнее'],
        servingsBase: 2,
        ingredients: const [
          RecipeIngredient(name: 'Вода', amount: 1, unit: Unit.l),
        ],
        steps: const ['Кипятить'],
      ),
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
  });
}

RecipeMatch _buildMatch({required Recipe recipe}) {
  return RecipeMatch(
    recipe: recipe,
    score: 0.9,
    missingIngredients: const [],
    matchedCount: recipe.ingredients.length,
    totalCount: recipe.ingredients.length,
    matchedRequired: recipe.ingredients.length,
    totalRequired: recipe.ingredients.length,
    matchedOptional: 0,
    totalOptional: 0,
  );
}
