import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/recipe.dart';
import '../domain/recipe_interaction_event.dart';

final recipeInteractionHistoryRepoProvider =
    Provider<RecipeInteractionHistoryRepo>((ref) {
  return const RecipeInteractionHistoryRepo();
});

class RecipeInteractionHistoryRepo {
  static const storageKey = 'recipe_interaction_history_v1';
  static const maxEntries = 240;

  const RecipeInteractionHistoryRepo();

  Future<List<RecipeInteractionEvent>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    final events = <RecipeInteractionEvent>[];
    for (final entry in decoded) {
      if (entry is! Map) {
        continue;
      }
      try {
        events.add(
          RecipeInteractionEvent.fromJson(Map<String, dynamic>.from(entry)),
        );
      } on Object {
        continue;
      }
    }

    events.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return events.take(maxEntries).toList();
  }

  Future<void> record({
    required RecipeInteractionType type,
    required Recipe recipe,
    DateTime? occurredAt,
  }) async {
    await recordMany(
      type: type,
      recipes: [recipe],
      occurredAt: occurredAt,
    );
  }

  Future<void> recordMany({
    required RecipeInteractionType type,
    required Iterable<Recipe> recipes,
    DateTime? occurredAt,
  }) async {
    final snapshots = recipes
        .where(
          (recipe) =>
              recipe.title.trim().isNotEmpty || recipe.ingredients.isNotEmpty,
        )
        .toList();
    if (snapshots.isEmpty) {
      return;
    }

    final events = [...await loadAll()];
    final timestamp = occurredAt ?? DateTime.now();
    events.insertAll(
      0,
      snapshots.map(
        (recipe) => RecipeInteractionEvent(
          type: type,
          recipeSnapshot: recipe,
          occurredAt: timestamp,
        ),
      ),
    );

    await _write(events.take(maxEntries).toList());
  }

  Future<void> replaceAll(List<RecipeInteractionEvent> events) async {
    final sorted = [...events]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    await _write(sorted.take(maxEntries).toList());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }

  Future<void> _write(List<RecipeInteractionEvent> events) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(events.map((event) => event.toJson()).toList());
    await prefs.setString(storageKey, payload);
  }
}
