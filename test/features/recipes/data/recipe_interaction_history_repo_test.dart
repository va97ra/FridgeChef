import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/recipes/data/recipe_interaction_history_repo.dart';
import 'package:help_to_cook/features/recipes/domain/recipe.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_ingredient.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_interaction_event.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('record and load preserve recipe snapshots in latest-first order',
      () async {
    const repo = RecipeInteractionHistoryRepo();
    final savedRecipe = Recipe(
      id: 'saved_recipe',
      title: 'Шеф-омлет',
      timeMin: 10,
      tags: const ['quick'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Яйцо', amount: 2, unit: Unit.pcs),
      ],
      steps: const ['Взбей', 'Пожарь'],
    );
    final deletedRecipe = Recipe(
      id: 'deleted_recipe',
      title: 'Сладкая овсянка',
      timeMin: 8,
      tags: const ['breakfast'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Овсяные хлопья', amount: 60, unit: Unit.g),
      ],
      steps: const ['Свари'],
    );

    await repo.record(
      type: RecipeInteractionType.saved,
      recipe: savedRecipe,
      occurredAt: DateTime(2026, 3, 9, 9),
    );
    await repo.record(
      type: RecipeInteractionType.deleted,
      recipe: deletedRecipe,
      occurredAt: DateTime(2026, 3, 9, 11),
    );

    final events = await repo.loadAll();

    expect(events, hasLength(2));
    expect(events.first.type, RecipeInteractionType.deleted);
    expect(events.first.recipeSnapshot.title, 'Сладкая овсянка');
    expect(events.last.type, RecipeInteractionType.saved);
    expect(events.last.recipeSnapshot.ingredients.single.name, 'Яйцо');
  });
}
