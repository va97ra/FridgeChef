import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../domain/generated_recipe_draft.dart';
import '../domain/recipe.dart';
import 'generated_recipe_draft_parser.dart';
import 'user_recipe_hive_dto.dart';

final userRecipesRepoProvider = Provider<UserRecipesRepo>((ref) {
  return UserRecipesRepo(
    boxName: 'userRecipesBox',
    parser: const GeneratedRecipeDraftParser(),
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
  final GeneratedRecipeDraftParser parser;
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
    final list = await _loadSanitizedRecipes();
    list.sort((a, b) {
      final aTime = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return list;
  }

  Future<List<Recipe>> findPotentialDuplicatesForRecipe(Recipe recipe) async {
    await _sanitizeStoredRecipes();
    final signature = buildRecipeSignatureFromRecipe(recipe);
    return _findPotentialDuplicatesBySignature(signature);
  }

  Future<List<Recipe>> findPotentialDuplicatesForDraft(
    GeneratedRecipeDraft draft,
  ) async {
    await _sanitizeStoredRecipes();
    final parsed = parser.parse(draft);
    final signature = buildRecipeSignature(
      title: parsed.title,
      ingredients: parsed.ingredients,
      steps: parsed.steps,
    );
    return _findPotentialDuplicatesBySignature(signature);
  }

  Future<List<Recipe>> _findPotentialDuplicatesBySignature(String signature) async {
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

  Future<SaveResult> saveGeneratedRecipe({
    required Recipe recipe,
    required SaveMode mode,
  }) async {
    final now = DateTime.now();
    await _sanitizeStoredRecipes();
    final duplicates = await findPotentialDuplicatesForRecipe(recipe);
    final box = _getBox();

    if (mode == SaveMode.updateExisting && duplicates.isNotEmpty) {
      final target = duplicates.first;
      final updated = _prepareGeneratedRecipeForSave(
        recipe,
        id: target.id,
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
    final baseTitle = recipe.title.trim().isEmpty
        ? 'Сохранённый рецепт'
        : recipe.title.trim();
    final titleForSave = duplicates.isEmpty
        ? baseTitle
        : _nextCopyTitle(baseTitle, existingTitles);

    final created = _prepareGeneratedRecipeForSave(
      recipe,
      id: _uuid.v4(),
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

  Future<SaveResult> saveFromGeneratedDraft({
    required GeneratedRecipeDraft draft,
    required SaveMode mode,
  }) async {
    final now = DateTime.now();
    final parsed = parser.parse(draft);
    final recipe = parsed.toRecipe(
      id: 'generated_draft',
      source: RecipeSource.generatedDraft,
      isUserEditable: false,
      createdAt: now,
      updatedAt: now,
    );
    return saveGeneratedRecipe(
      recipe: recipe,
      mode: mode,
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

  Future<void> clearAll() async {
    await _getBox().clear();
  }

  Future<void> replaceAllUserRecipes(List<Recipe> recipes) async {
    final box = _getBox();
    await box.clear();
    if (recipes.isEmpty) {
      return;
    }
    await box.putAll({
      for (final recipe in recipes) recipe.id: _recipeToDto(recipe),
    });
  }

  Future<List<Recipe>> _loadSanitizedRecipes() async {
    final box = _getBox();
    final recipes = <Recipe>[];
    final invalidKeys = <dynamic>[];

    for (final entry in box.toMap().entries) {
      final recipe = _dtoToRecipeOrNull(entry.value);
      if (recipe == null) {
        invalidKeys.add(entry.key);
        continue;
      }
      recipes.add(recipe);
    }

    if (invalidKeys.isNotEmpty) {
      await box.deleteAll(invalidKeys);
    }
    return recipes;
  }

  Future<void> _sanitizeStoredRecipes() async {
    await _loadSanitizedRecipes();
  }

  Recipe _dtoToRecipe(UserRecipeHiveDto dto) {
    final recipe = _dtoToRecipeOrNull(dto);
    if (recipe == null) {
      throw const FormatException('Stored recipe is malformed or unsupported');
    }
    return recipe;
  }

  Recipe? _dtoToRecipeOrNull(UserRecipeHiveDto dto) {
    try {
      final jsonMap = jsonDecode(dto.recipeJson) as Map<String, dynamic>;
      return Recipe.fromJson(jsonMap);
    } on Object {
      return null;
    }
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

  Recipe _prepareGeneratedRecipeForSave(
    Recipe recipe, {
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? titleOverride,
  }) {
    final tags = <String>{
      ...recipe.tags.where((tag) => tag.trim().isNotEmpty),
      'generated_local',
    }.toList();

    return recipe.copyWith(
      id: id,
      title: titleOverride?.trim().isNotEmpty == true
          ? titleOverride!.trim()
          : recipe.title,
      tags: tags,
      source: RecipeSource.generatedSaved,
      isUserEditable: true,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String _nextCopyTitle(String baseTitle, Set<String> existingTitles) {
    final trimmed = baseTitle.trim().isEmpty
        ? 'Сохранённый рецепт'
        : baseTitle.trim();
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
