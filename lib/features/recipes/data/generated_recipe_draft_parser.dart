import '../../../core/utils/units.dart';
import '../domain/generated_recipe_draft.dart';
import '../domain/recipe.dart';
import '../domain/recipe_ingredient.dart';

class ParsedRecipeDraft {
  final String title;
  final String? description;
  final int timeMin;
  final int servingsBase;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;

  const ParsedRecipeDraft({
    required this.title,
    this.description,
    required this.timeMin,
    required this.servingsBase,
    required this.ingredients,
    required this.steps,
  });

  Recipe toRecipe({
    required String id,
    required RecipeSource source,
    required bool isUserEditable,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? titleOverride,
  }) {
    return Recipe(
      id: id,
      title: titleOverride?.trim().isNotEmpty == true
          ? titleOverride!.trim()
          : title,
      description: description,
      timeMin: timeMin,
      tags: const ['generated_local'],
      servingsBase: servingsBase,
      ingredients: ingredients,
      steps: steps,
      source: source,
      isUserEditable: isUserEditable,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class GeneratedRecipeDraftParser {
  const GeneratedRecipeDraftParser();

  ParsedRecipeDraft parse(GeneratedRecipeDraft draft) {
    final parsedIngredients = draft.ingredients
        .where((e) => e.trim().isNotEmpty)
        .map(_parseIngredientLine)
        .toList();

    final steps = draft.steps
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return ParsedRecipeDraft(
      title: draft.title.trim().isEmpty
          ? 'Сохранённый рецепт'
          : draft.title.trim(),
      description: _sanitizeDescription(draft.tip),
      timeMin: draft.timeMin > 0 ? draft.timeMin : 20,
      servingsBase: draft.servings > 0 ? draft.servings : 2,
      ingredients: parsedIngredients.isEmpty
          ? const [
              RecipeIngredient(
                name: 'Ингредиент',
                amount: 1,
                unit: Unit.pcs,
                required: false,
              ),
            ]
          : parsedIngredients,
      steps: steps.isEmpty ? const ['Приготовьте блюдо по описанию.'] : steps,
    );
  }

  RecipeIngredient _parseIngredientLine(String rawLine) {
    var line = rawLine.trim().replaceAll('—', '-').replaceAll('–', '-');
    final separatorIndex = line.indexOf('-');

    String namePart;
    String amountPart;
    if (separatorIndex >= 0) {
      namePart = line.substring(0, separatorIndex).trim();
      amountPart = line.substring(separatorIndex + 1).trim();
    } else {
      namePart = line;
      amountPart = '';
    }

    final normalizedAmount = amountPart.toLowerCase();
    if (normalizedAmount.contains('по вкусу')) {
      return RecipeIngredient(
        name: _sanitizeName(namePart),
        amount: 1,
        unit: Unit.pcs,
        required: false,
      );
    }

    final amountMatch = RegExp(r'(\d+(?:[.,]\d+)?)').firstMatch(normalizedAmount);
    final parsedAmount = amountMatch == null
        ? null
        : double.tryParse(amountMatch.group(1)!.replaceAll(',', '.'));
    final unit = _parseUnit(normalizedAmount);

    if (parsedAmount == null || parsedAmount <= 0) {
      return RecipeIngredient(
        name: _sanitizeName(namePart),
        amount: 1,
        unit: Unit.pcs,
        required: false,
      );
    }

    return RecipeIngredient(
      name: _sanitizeName(namePart),
      amount: parsedAmount,
      unit: unit,
      required: true,
    );
  }

  Unit _parseUnit(String raw) {
    final value = raw.toLowerCase();
    if (RegExp(r'(^|[\s\d])(кг|килограмм)').hasMatch(value)) {
      return Unit.kg;
    }
    if (RegExp(r'(^|[\s\d])(мл|миллилитр)').hasMatch(value)) {
      return Unit.ml;
    }
    if (RegExp(r'(^|[\s\d])(л|литр)').hasMatch(value) &&
        !value.contains('мл')) {
      return Unit.l;
    }
    if (RegExp(r'(^|[\s\d])(г|гр|грам)').hasMatch(value) &&
        !value.contains('кг')) {
      return Unit.g;
    }
    if (RegExp(r'(шт|штук|штуки|pcs)').hasMatch(value)) {
      return Unit.pcs;
    }
    return Unit.pcs;
  }

  String _sanitizeName(String raw) {
    final cleaned = raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[,;:\-]+|[,;:\-]+$'), '')
        .trim();
    return cleaned.isEmpty ? 'Ингредиент' : cleaned;
  }

  String? _sanitizeDescription(String? raw) {
    final cleaned = raw?.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned == null || cleaned.isEmpty) {
      return null;
    }
    return cleaned;
  }
}

String buildRecipeSignature({
  required String title,
  required List<RecipeIngredient> ingredients,
  required List<String> steps,
}) {
  final normalizedTitle = _normalize(title);
  final ingredientTokens = ingredients
      .map(
        (e) =>
            '${_normalize(e.name)}|${_num(e.amount)}|${e.unit.name}|${e.required ? 1 : 0}',
      )
      .toList()
    ..sort();
  final normalizedSteps = steps.map(_normalize).where((e) => e.isNotEmpty).toList();

  return [
    normalizedTitle,
    ingredientTokens.join('||'),
    normalizedSteps.join('||'),
  ].join('###');
}

String buildRecipeSignatureFromRecipe(Recipe recipe) {
  return buildRecipeSignature(
    title: recipe.title,
    ingredients: recipe.ingredients,
    steps: recipe.steps,
  );
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _num(double value) {
  if (value == value.truncateToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '').replaceFirst(
        RegExp(r'\.$'),
        '',
      );
}
