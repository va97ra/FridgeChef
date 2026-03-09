import 'recipe_ingredient.dart';

enum RecipeSource { asset, generatedDraft, generatedSaved }

extension RecipeSourceX on RecipeSource {
  String get storageValue {
    switch (this) {
      case RecipeSource.asset:
        return 'asset';
      case RecipeSource.generatedDraft:
        return 'generated_draft';
      case RecipeSource.generatedSaved:
        return 'generated_saved';
    }
  }

  static RecipeSource fromStorage(String? value) {
    switch (value) {
      case null:
      case '':
      case 'asset':
        return RecipeSource.asset;
      case 'generated_draft':
      case 'generatedDraft':
        return RecipeSource.generatedDraft;
      case 'generated_saved':
      case 'generatedSaved':
        return RecipeSource.generatedSaved;
      default:
        throw FormatException('Unsupported recipe source: $value');
    }
  }
}

class Recipe {
  final String id;
  final String title;
  final String? description;
  final int timeMin;
  final List<String> tags;
  final int servingsBase;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final RecipeSource source;
  final bool isUserEditable;
  final List<String> anchorIngredients;
  final List<String> implicitPantryItems;
  final String? chefProfile;
  final double chefPriorityScore;
  final List<String> chefNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Recipe({
    required this.id,
    required this.title,
    this.description,
    required this.timeMin,
    required this.tags,
    required this.servingsBase,
    required this.ingredients,
    required this.steps,
    this.source = RecipeSource.asset,
    this.isUserEditable = false,
    this.anchorIngredients = const [],
    this.implicitPantryItems = const [],
    this.chefProfile,
    this.chefPriorityScore = 0,
    this.chefNotes = const [],
    this.createdAt,
    this.updatedAt,
  });

  bool get isGenerated =>
      source == RecipeSource.generatedDraft ||
      source == RecipeSource.generatedSaved;

  bool get isSavedGenerated => source == RecipeSource.generatedSaved;

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      timeMin: json['timeMin'] as int,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
      servingsBase: json['servingsBase'] as int,
      ingredients: (json['ingredients'] as List<dynamic>)
          .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      steps: (json['steps'] as List<dynamic>).map((e) => e as String).toList(),
      source: RecipeSourceX.fromStorage(json['source'] as String?),
      isUserEditable: json['isUserEditable'] as bool? ?? false,
      anchorIngredients: (json['anchorIngredients'] as List<dynamic>?)
              ?.map((e) => '$e')
              .toList() ??
          const [],
      implicitPantryItems: (json['implicitPantryItems'] as List<dynamic>?)
              ?.map((e) => '$e')
              .toList() ??
          const [],
      chefProfile: json['chefProfile'] as String?,
      chefPriorityScore:
          (json['chefPriorityScore'] as num?)?.toDouble() ?? 0,
      chefNotes:
          (json['chefNotes'] as List<dynamic>?)?.map((e) => '$e').toList() ??
              const [],
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'timeMin': timeMin,
      'tags': tags,
      'servingsBase': servingsBase,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      'steps': steps,
      'source': source.storageValue,
      'isUserEditable': isUserEditable,
      'anchorIngredients': anchorIngredients,
      'implicitPantryItems': implicitPantryItems,
      'chefProfile': chefProfile,
      'chefPriorityScore': chefPriorityScore,
      'chefNotes': chefNotes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Recipe copyWith({
    String? id,
    String? title,
    String? description,
    int? timeMin,
    List<String>? tags,
    int? servingsBase,
    List<RecipeIngredient>? ingredients,
    List<String>? steps,
    RecipeSource? source,
    bool? isUserEditable,
    List<String>? anchorIngredients,
    List<String>? implicitPantryItems,
    String? chefProfile,
    double? chefPriorityScore,
    List<String>? chefNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      timeMin: timeMin ?? this.timeMin,
      tags: tags ?? this.tags,
      servingsBase: servingsBase ?? this.servingsBase,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      source: source ?? this.source,
      isUserEditable: isUserEditable ?? this.isUserEditable,
      anchorIngredients: anchorIngredients ?? this.anchorIngredients,
      implicitPantryItems: implicitPantryItems ?? this.implicitPantryItems,
      chefProfile: chefProfile ?? this.chefProfile,
      chefPriorityScore: chefPriorityScore ?? this.chefPriorityScore,
      chefNotes: chefNotes ?? this.chefNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
