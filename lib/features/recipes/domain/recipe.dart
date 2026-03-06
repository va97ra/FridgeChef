import 'recipe_ingredient.dart';

enum RecipeSource { asset, aiSaved }

extension RecipeSourceX on RecipeSource {
  String get storageValue {
    switch (this) {
      case RecipeSource.asset:
        return 'asset';
      case RecipeSource.aiSaved:
        return 'ai_saved';
    }
  }

  static RecipeSource fromStorage(String? value) {
    switch (value) {
      case 'ai_saved':
      case 'aiSaved':
        return RecipeSource.aiSaved;
      default:
        return RecipeSource.asset;
    }
  }
}

class Recipe {
  final String id;
  final String title;
  final int timeMin;
  final List<String> tags;
  final int servingsBase;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final RecipeSource source;
  final bool isUserEditable;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Recipe({
    required this.id,
    required this.title,
    required this.timeMin,
    required this.tags,
    required this.servingsBase,
    required this.ingredients,
    required this.steps,
    this.source = RecipeSource.asset,
    this.isUserEditable = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      title: json['title'] as String,
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
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'timeMin': timeMin,
      'tags': tags,
      'servingsBase': servingsBase,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      'steps': steps,
      'source': source.storageValue,
      'isUserEditable': isUserEditable,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Recipe copyWith({
    String? id,
    String? title,
    int? timeMin,
    List<String>? tags,
    int? servingsBase,
    List<RecipeIngredient>? ingredients,
    List<String>? steps,
    RecipeSource? source,
    bool? isUserEditable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      timeMin: timeMin ?? this.timeMin,
      tags: tags ?? this.tags,
      servingsBase: servingsBase ?? this.servingsBase,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      source: source ?? this.source,
      isUserEditable: isUserEditable ?? this.isUserEditable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
