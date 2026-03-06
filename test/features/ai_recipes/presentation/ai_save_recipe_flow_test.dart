import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/ai_recipes/domain/ai_recipe.dart';
import 'package:help_to_cook/features/ai_recipes/presentation/ai_save_recipe_flow.dart';
import 'package:help_to_cook/features/recipes/data/ai_to_recipe_parser.dart';
import 'package:help_to_cook/features/recipes/data/user_recipes_repo.dart';
import 'package:help_to_cook/features/recipes/domain/recipe.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_ingredient.dart';

void main() {
  testWidgets('shows duplicate dialog with three actions', (tester) async {
    final duplicateRecipe = Recipe(
      id: 'dup',
      title: 'Омлет',
      timeMin: 10,
      tags: const [],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Яйцо', amount: 2, unit: Unit.pcs),
      ],
      steps: const ['Шаг 1'],
      source: RecipeSource.aiSaved,
      isUserEditable: true,
    );
    final repo = _FakeDialogUserRecipesRepo([duplicateRecipe]);
    const aiRecipe = AiRecipe(
      title: 'Омлет',
      timeMin: 10,
      servings: 2,
      ingredients: ['Яйцо - 2 шт'],
      steps: ['Шаг 1'],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userRecipesRepoProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          home: _DialogHost(aiRecipe: aiRecipe),
        ),
      ),
    );

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Рецепт уже сохранён'), findsOneWidget);
    expect(find.text('Обновить существующий'), findsOneWidget);
    expect(find.text('Сохранить копию'), findsOneWidget);
    expect(find.text('Отмена'), findsOneWidget);
  });
}

class _DialogHost extends ConsumerWidget {
  final AiRecipe aiRecipe;

  const _DialogHost({required this.aiRecipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () async {
            await saveAiRecipeWithDialog(
              context: context,
              ref: ref,
              aiRecipe: aiRecipe,
            );
          },
          child: const Text('save'),
        ),
      ),
    );
  }
}

class _FakeDialogUserRecipesRepo extends UserRecipesRepo {
  final List<Recipe> duplicates;

  _FakeDialogUserRecipesRepo(this.duplicates)
      : super(
          boxName: 'unused',
          parser: const AiToRecipeParser(),
        );

  @override
  Future<List<Recipe>> findPotentialDuplicates(AiRecipe aiRecipe) async {
    return duplicates;
  }

  @override
  Future<SaveResult> saveFromAi({
    required AiRecipe aiRecipe,
    required SaveMode mode,
  }) async {
    return SaveResult(
      recipe: duplicates.first,
      action: SaveAction.updatedExisting,
      duplicates: duplicates,
    );
  }
}
