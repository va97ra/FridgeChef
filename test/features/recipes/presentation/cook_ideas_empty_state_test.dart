import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/features/recipes/domain/recipe.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_match.dart';
import 'package:help_to_cook/features/recipes/presentation/cook_ideas_screen.dart';
import 'package:help_to_cook/features/recipes/presentation/providers.dart';

void main() {
  testWidgets('empty cook screen shows CTA to fridge', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recipesProvider.overrideWith((ref) async => const <Recipe>[]),
          productCatalogProvider.overrideWith((ref) async => const []),
          recipeMatchesProvider.overrideWith((ref) => const <RecipeMatch>[]),
        ],
        child: const MaterialApp(home: CookIdeasScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Перейти в холодильник'), findsOneWidget);
  });
}
