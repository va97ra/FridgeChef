import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/recipes/data/ai_to_recipe_parser.dart';
import 'package:help_to_cook/features/recipes/data/recipes_loader.dart';
import 'package:help_to_cook/features/recipes/data/recipes_repo.dart';
import 'package:help_to_cook/features/recipes/data/user_recipes_repo.dart';
import 'package:help_to_cook/features/recipes/domain/recipe.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_ingredient.dart';

void main() {
  test('merges assets and user recipes into unified list', () async {
    final assetRecipe = Recipe(
      id: 'asset_1',
      title: 'Суп',
      timeMin: 30,
      tags: const ['asset'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Вода', amount: 1, unit: Unit.l),
      ],
      steps: const ['Кипятить'],
    );
    final userRecipe = Recipe(
      id: 'user_1',
      title: 'AI Омлет',
      timeMin: 10,
      tags: const ['ai_saved'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Яйцо', amount: 2, unit: Unit.pcs),
      ],
      steps: const ['Пожарить'],
      source: RecipeSource.aiSaved,
      isUserEditable: true,
    );

    final repo = RecipesRepo(
      loader: _FakeRecipesLoader([assetRecipe]),
      userRecipesRepo: _FakeUserRecipesRepo([userRecipe]),
    );
    final all = await repo.getAll();

    expect(all.length, 2);
    expect(all.first.id, 'asset_1');
    expect(all.last.id, 'user_1');
    expect(all.last.source, RecipeSource.aiSaved);
  });
}

class _FakeRecipesLoader extends RecipesLoader {
  final List<Recipe> recipes;

  const _FakeRecipesLoader(this.recipes);

  @override
  Future<List<Recipe>> loadRecipes() async => recipes;
}

class _FakeUserRecipesRepo extends UserRecipesRepo {
  final List<Recipe> recipes;

  _FakeUserRecipesRepo(this.recipes)
      : super(
          boxName: 'unused',
          parser: const AiToRecipeParser(),
        );

  @override
  Future<List<Recipe>> getAllUserRecipes() async => recipes;
}
