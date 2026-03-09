import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/fridge/domain/product_catalog_entry.dart';
import 'package:help_to_cook/features/recipes/domain/recipe.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_ingredient.dart';
import 'package:help_to_cook/features/recipes/domain/taste_profile.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_ingredient_canonicalizer.dart';

void main() {
  test('taste profile prefers recipes similar to liked ones', () {
    final likedRecipe = Recipe(
      id: 'liked',
      title: 'Омлет с сыром',
      timeMin: 10,
      tags: const ['breakfast', 'one_pan'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Яйцо', amount: 2, unit: Unit.pcs),
        RecipeIngredient(name: 'Сыр', amount: 40, unit: Unit.g),
      ],
      steps: const ['Взбей', 'Пожарь'],
    );
    final similarRecipe = Recipe(
      id: 'similar',
      title: 'Яичница с помидорами',
      timeMin: 9,
      tags: const ['breakfast', 'one_pan'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Яйцо', amount: 2, unit: Unit.pcs),
        RecipeIngredient(name: 'Помидор', amount: 120, unit: Unit.g),
      ],
      steps: const ['Пожарь', 'Подавай'],
    );
    final distantRecipe = Recipe(
      id: 'distant',
      title: 'Сладкая овсянка',
      timeMin: 8,
      tags: const ['breakfast'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Овсяные хлопья', amount: 60, unit: Unit.g),
        RecipeIngredient(name: 'Сахар', amount: 10, unit: Unit.g),
      ],
      steps: const ['Свари', 'Подавай'],
    );

    final catalog = const [
      ProductCatalogEntry(
        id: 'egg',
        name: 'Яйцо',
        canonicalName: 'Яйцо',
        synonyms: ['Яйца'],
        defaultUnit: Unit.pcs,
      ),
      ProductCatalogEntry(
        id: 'cheese',
        name: 'Сыр',
        canonicalName: 'Сыр',
        synonyms: [],
        defaultUnit: Unit.g,
      ),
      ProductCatalogEntry(
        id: 'tomato',
        name: 'Помидор',
        canonicalName: 'Помидор',
        synonyms: ['Помидоры'],
        defaultUnit: Unit.g,
      ),
      ProductCatalogEntry(
        id: 'oats',
        name: 'Овсяные хлопья',
        canonicalName: 'Овсяные хлопья',
        synonyms: ['Овсянка'],
        defaultUnit: Unit.g,
      ),
      ProductCatalogEntry(
        id: 'sugar',
        name: 'Сахар',
        canonicalName: 'Сахар',
        synonyms: [],
        defaultUnit: Unit.g,
      ),
    ];

    final profile = buildTasteProfile(
      feedbackByRecipeId: const {'liked': RecipeFeedbackVote.liked},
      recipes: [likedRecipe, similarRecipe, distantRecipe],
      catalog: catalog,
    );

    final canonicalizer =
        RecipeIngredientCanonicalizer(catalog);
    final similarAnalysis = profile.analyzeRecipe(
      recipe: similarRecipe,
      canonicalizer: canonicalizer,
    );
    final distantAnalysis = profile.analyzeRecipe(
      recipe: distantRecipe,
      canonicalizer: canonicalizer,
    );

    expect(similarAnalysis.score, greaterThan(distantAnalysis.score));
    expect(similarAnalysis.reasons, isNotEmpty);
  });
}
