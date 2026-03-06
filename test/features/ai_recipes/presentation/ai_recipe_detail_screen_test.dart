import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/features/ai_recipes/domain/ai_recipe.dart';
import 'package:help_to_cook/features/ai_recipes/presentation/ai_recipe_detail_screen.dart';

void main() {
  testWidgets('shows save button on AI recipe details screen', (tester) async {
    const recipe = AiRecipe(
      title: 'Омлет',
      timeMin: 10,
      servings: 2,
      ingredients: ['Яйцо - 2 шт'],
      steps: ['Шаг 1'],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: AiRecipeDetailScreen(recipe: recipe),
        ),
      ),
    );

    expect(find.text('Сохранить в мои рецепты'), findsOneWidget);
  });
}
