import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/user_recipes_repo.dart';
import '../domain/recipe.dart';
import '../domain/recipe_interaction_event.dart';
import 'providers.dart';

Future<SaveResult?> saveGeneratedRecipeWithDialog({
  required BuildContext context,
  required WidgetRef ref,
  required Recipe recipe,
}) async {
  final repo = ref.read(userRecipesRepoProvider);
  final duplicates = await repo.findPotentialDuplicatesForRecipe(recipe);

  var mode = SaveMode.createCopy;
  if (duplicates.isNotEmpty && context.mounted) {
    final selected = await showDialog<SaveMode>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Рецепт уже сохранён'),
          content: Text(
            'Найдено совпадение: "${duplicates.first.title}". Что сделать?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, SaveMode.createCopy),
              child: const Text('Сохранить копию'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, SaveMode.updateExisting),
              child: const Text('Обновить существующий'),
            ),
          ],
        );
      },
    );
    if (selected == null) {
      return null;
    }
    mode = selected;
  }

  final result = await repo.saveGeneratedRecipe(recipe: recipe, mode: mode);
  await ref.read(recipeInteractionHistoryProvider.notifier).record(
        type: RecipeInteractionType.saved,
        recipe: result.recipe,
      );
  ref.invalidate(recipesProvider);
  ref.invalidate(recipeMatchesProvider);
  return result;
}
