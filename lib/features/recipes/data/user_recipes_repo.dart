import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../ai_recipes/domain/ai_recipe.dart';
import '../domain/recipe.dart';
import 'ai_to_recipe_parser.dart';
import 'user_recipe_hive_dto.dart';

final userRecipesRepoProvider = Provider<UserRecipesRepo>((ref) {
  return UserRecipesRepo(
    boxName: 'userRecipesBox',
    parser: const AiToRecipeParser(),
  );
});

enum SaveMode { createCopy, updateExisting }

enum SaveAction { created, createdCopy, updatedExisting }

class SaveResult {
  final Recipe recipe;
  final SaveAction action;
  final List<Recipe> duplicates;

  const SaveResult({
    required this.recipe,
    required this.action,
    required this.duplicates,
  });

  bool get hadDuplicates => duplicates.isNotEmpty;
}

class UserRecipesRepo {
  final String boxName;
  final AiToRecipeParser parser;
  final Uuid _uuid;

  UserRecipesRepo({
    required this.boxName,
    required this.parser,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  Box<UserRecipeHiveDto> _getBox() {
    return Hive.box<UserRecipeHiveDto>(boxName);
  }

  Future<List<Recipe>> getAllUserRecipes() async {
    final list = _getBox().values.map(_dtoToRecipe).toList();
    list.sort((a, b) {
      final aTime = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return list;
  }

  Future<List<Recipe>> findPotentialDuplicates(AiRecipe aiRecipe) async {
    final draft = parser.parse(aiRecipe);
    final signature = buildRecipeSignature(
      title: draft.title,
      ingredients: draft.ingredients,
      steps: draft.steps,
    );

    final duplicates = _getBox().values
        .where((dto) => dto.signature == signature)
        .map(_dtoToRecipe)
        .toList();

    duplicates.sort((a, b) {
      final aTime = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return duplicates;
  }

  Future<SaveResult> saveFromAi({
    required AiRecipe aiRecipe,
    required SaveMode mode,
  }) async {
    final now = DateTime.now();
    final draft = parser.parse(aiRecipe);
    final duplicates = await findPotentialDuplicates(aiRecipe);
    final box = _getBox();

    if (mode == SaveMode.updateExisting && duplicates.isNotEmpty) {
      final target = duplicates.first;
      final updated = draft.toRecipe(
        id: target.id,
        source: RecipeSource.aiSaved,
        isUserEditable: true,
        createdAt: target.createdAt ?? now,
        updatedAt: now,
      );
      final dto = _recipeToDto(updated);
      await box.put(dto.id, dto);
      return SaveResult(
        recipe: updated,
        action: SaveAction.updatedExisting,
        duplicates: duplicates,
      );
    }

    final existingTitles =
        box.values.map((dto) => _dtoToRecipe(dto).title.trim()).toSet();
    final titleForSave = duplicates.isEmpty
        ? draft.title
        : _nextCopyTitle(draft.title, existingTitles);

    final created = draft.toRecipe(
      id: _uuid.v4(),
      source: RecipeSource.aiSaved,
      isUserEditable: true,
      createdAt: now,
      updatedAt: now,
      titleOverride: titleForSave,
    );

    final dto = _recipeToDto(created);
    await box.put(dto.id, dto);
    return SaveResult(
      recipe: created,
      action: duplicates.isEmpty ? SaveAction.created : SaveAction.createdCopy,
      duplicates: duplicates,
    );
  }

  Future<void> renameUserRecipe(String id, String newTitle) async {
    final box = _getBox();
    final dto = box.get(id);
    if (dto == null) {
      return;
    }

    final recipe = _dtoToRecipe(dto);
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final updated = recipe.copyWith(
      title: trimmed,
      updatedAt: DateTime.now(),
    );
    await box.put(id, _recipeToDto(updated));
  }

  Future<void> deleteUserRecipe(String id) async {
    await _getBox().delete(id);
  }

  Recipe _dtoToRecipe(UserRecipeHiveDto dto) {
    final jsonMap = jsonDecode(dto.recipeJson) as Map<String, dynamic>;
    return Recipe.fromJson(jsonMap);
  }

  UserRecipeHiveDto _recipeToDto(Recipe recipe) {
    final signature = buildRecipeSignatureFromRecipe(recipe);
    final now = DateTime.now();
    return UserRecipeHiveDto(
      id: recipe.id,
      recipeJson: jsonEncode(recipe.toJson()),
      signature: signature,
      createdAt: recipe.createdAt ?? now,
      updatedAt: recipe.updatedAt ?? now,
    );
  }

  String _nextCopyTitle(String baseTitle, Set<String> existingTitles) {
    final trimmed = baseTitle.trim().isEmpty ? 'AI Рецепт' : baseTitle.trim();
    var candidate = '$trimmed (копия)';
    if (!existingTitles.contains(candidate)) {
      return candidate;
    }

    var index = 2;
    while (true) {
      candidate = '$trimmed (копия $index)';
      if (!existingTitles.contains(candidate)) {
        return candidate;
      }
      index++;
    }
  }
}
