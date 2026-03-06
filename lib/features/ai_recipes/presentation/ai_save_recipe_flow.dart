import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../recipes/data/user_recipes_repo.dart';
import '../../recipes/presentation/providers.dart';
import '../domain/ai_recipe.dart';

Future<SaveResult?> saveAiRecipeWithDialog({
  required BuildContext context,
  required WidgetRef ref,
  required AiRecipe aiRecipe,
}) async {
  final repo = ref.read(userRecipesRepoProvider);
  final duplicates = await repo.findPotentialDuplicates(aiRecipe);

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

  final result = await repo.saveFromAi(aiRecipe: aiRecipe, mode: mode);
  ref.invalidate(recipesProvider);
  return result;
}
