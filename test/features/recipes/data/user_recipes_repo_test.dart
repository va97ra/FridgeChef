import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/features/ai_recipes/domain/ai_recipe.dart';
import 'package:help_to_cook/features/recipes/data/ai_to_recipe_parser.dart';
import 'package:help_to_cook/features/recipes/data/user_recipe_hive_dto.dart';
import 'package:help_to_cook/features/recipes/data/user_recipes_repo.dart';
import 'package:help_to_cook/features/recipes/domain/recipe.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_ingredient.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('user_recipes_repo_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(UserRecipeHiveDtoAdapter());
    }
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('finds duplicate by deterministic signature', () async {
    const boxName = 'userRecipesBox_duplicates';
    final repo = await _openRepo(boxName);
    try {
      const aiBase = AiRecipe(
        title: 'Омлет',
        timeMin: 10,
        servings: 2,
        ingredients: [
          'Яйцо - 2 шт',
          'Молоко - 100 мл',
        ],
        steps: ['Смешай', 'Пожарь'],
      );
      const aiSameContentDifferentOrder = AiRecipe(
        title: 'Омлет',
        timeMin: 12,
        servings: 2,
        ingredients: [
          'Молоко - 100 мл',
          'Яйцо - 2 шт',
        ],
        steps: ['Смешай', 'Пожарь'],
      );

      await repo.saveFromAi(aiRecipe: aiBase, mode: SaveMode.createCopy);
      final duplicates =
          await repo.findPotentialDuplicates(aiSameContentDifferentOrder);
      expect(duplicates, isNotEmpty);
    } finally {
      await _closeAndDeleteBox(boxName);
    }
  });

  test('saveFromAi update mode rewrites existing recipe', () async {
    const boxName = 'userRecipesBox_update';
    final repo = await _openRepo(boxName);
    try {
      const original = AiRecipe(
        title: 'Омлет',
        timeMin: 10,
        servings: 2,
        ingredients: ['Яйцо - 2 шт'],
        steps: ['Шаг 1'],
      );
      const changed = AiRecipe(
        title: 'Омлет',
        timeMin: 25,
        servings: 3,
        ingredients: ['Яйцо - 2 шт'],
        steps: ['Шаг 1'],
      );

      await repo.saveFromAi(aiRecipe: original, mode: SaveMode.createCopy);
      final result =
          await repo.saveFromAi(aiRecipe: changed, mode: SaveMode.updateExisting);
      final all = await repo.getAllUserRecipes();

      expect(result.action, SaveAction.updatedExisting);
      expect(all.length, 1);
      expect(all.first.timeMin, 25);
      expect(all.first.servingsBase, 3);
      expect(all.first.steps.length, 1);
    } finally {
      await _closeAndDeleteBox(boxName);
    }
  });

  test('saveFromAi copy mode creates second recipe with copy suffix', () async {
    const boxName = 'userRecipesBox_copy';
    final repo = await _openRepo(boxName);
    try {
      const aiRecipe = AiRecipe(
        title: 'Омлет',
        timeMin: 10,
        servings: 2,
        ingredients: ['Яйцо - 2 шт'],
        steps: ['Шаг 1'],
      );

      await repo.saveFromAi(aiRecipe: aiRecipe, mode: SaveMode.createCopy);
      final result =
          await repo.saveFromAi(aiRecipe: aiRecipe, mode: SaveMode.createCopy);
      final all = await repo.getAllUserRecipes();

      expect(result.action, SaveAction.createdCopy);
      expect(all.length, 2);
      expect(
        all.any((recipe) => recipe.title.contains('(копия')),
        isTrue,
      );
    } finally {
      await _closeAndDeleteBox(boxName);
    }
  });

  test('saveGeneratedRecipe persists generated source and chef metadata', () async {
    const boxName = 'userRecipesBox_generated_recipe';
    final repo = await _openRepo(boxName);
    try {
      const generatedRecipe = Recipe(
        id: 'draft',
        title: 'Шеф-омлет',
        timeMin: 12,
        tags: ['generated_local', 'breakfast'],
        servingsBase: 2,
        ingredients: [
          RecipeIngredient(name: 'Яйца', amount: 3, unit: Unit.pcs),
          RecipeIngredient(name: 'Сыр', amount: 120, unit: Unit.g),
        ],
        steps: ['Шаг 1', 'Шаг 2'],
        source: RecipeSource.generatedDraft,
        anchorIngredients: ['Яйца'],
        implicitPantryItems: ['Соль'],
        chefProfile: 'skillet',
      );

      final result = await repo.saveGeneratedRecipe(
        recipe: generatedRecipe,
        mode: SaveMode.createCopy,
      );
      final all = await repo.getAllUserRecipes();

      expect(result.recipe.source, RecipeSource.generatedSaved);
      expect(all.single.source, RecipeSource.generatedSaved);
      expect(all.single.isUserEditable, isTrue);
      expect(all.single.anchorIngredients, ['Яйца']);
      expect(all.single.implicitPantryItems, ['Соль']);
      expect(all.single.chefProfile, 'skillet');
    } finally {
      await _closeAndDeleteBox(boxName);
    }
  });
}

Future<UserRecipesRepo> _openRepo(String boxName) async {
  if (!Hive.isBoxOpen(boxName)) {
    await Hive.openBox<UserRecipeHiveDto>(boxName);
  }
  return UserRecipesRepo(
    boxName: boxName,
    parser: const AiToRecipeParser(),
  );
}

Future<void> _closeAndDeleteBox(String boxName) async {
  if (Hive.isBoxOpen(boxName)) {
    await Hive.box<UserRecipeHiveDto>(boxName).close();
  }
  await Hive.deleteBoxFromDisk(boxName);
}
