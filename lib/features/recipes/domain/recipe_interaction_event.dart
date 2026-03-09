import 'recipe.dart';

enum RecipeInteractionType { saved, renamed, deleted, recooked, ignored }

extension RecipeInteractionTypeX on RecipeInteractionType {
  String get storageValue {
    switch (this) {
      case RecipeInteractionType.saved:
        return 'saved';
      case RecipeInteractionType.renamed:
        return 'renamed';
      case RecipeInteractionType.deleted:
        return 'deleted';
      case RecipeInteractionType.recooked:
        return 'recooked';
      case RecipeInteractionType.ignored:
        return 'ignored';
    }
  }

  static RecipeInteractionType? fromStorage(String? raw) {
    switch (raw) {
      case 'saved':
        return RecipeInteractionType.saved;
      case 'renamed':
        return RecipeInteractionType.renamed;
      case 'deleted':
        return RecipeInteractionType.deleted;
      case 'recooked':
        return RecipeInteractionType.recooked;
      case 'ignored':
        return RecipeInteractionType.ignored;
      default:
        return null;
    }
  }
}

class RecipeInteractionEvent {
  final RecipeInteractionType type;
  final Recipe recipeSnapshot;
  final DateTime occurredAt;

  const RecipeInteractionEvent({
    required this.type,
    required this.recipeSnapshot,
    required this.occurredAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.storageValue,
      'occurredAt': occurredAt.toIso8601String(),
      'recipe': recipeSnapshot.toJson(),
    };
  }

  factory RecipeInteractionEvent.fromJson(Map<String, dynamic> json) {
    final type = RecipeInteractionTypeX.fromStorage(json['type'] as String?);
    final occurredAt = DateTime.tryParse(json['occurredAt'] as String? ?? '');
    final recipeJson = json['recipe'];
    if (type == null || occurredAt == null || recipeJson is! Map) {
      throw const FormatException('Malformed recipe interaction event');
    }

    return RecipeInteractionEvent(
      type: type,
      occurredAt: occurredAt,
      recipeSnapshot: Recipe.fromJson(Map<String, dynamic>.from(recipeJson)),
    );
  }
}
