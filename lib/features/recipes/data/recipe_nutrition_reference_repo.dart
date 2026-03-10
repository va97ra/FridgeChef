import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/recipe_nutrition.dart';

final recipeNutritionReferenceRepoProvider =
    Provider<RecipeNutritionReferenceRepo>((ref) {
  return const RecipeNutritionReferenceRepo();
});

class RecipeNutritionReferenceRepo {
  static const _catalogPath = 'assets/products/nutrition_reference_ru.json';
  static List<NutritionReferenceEntry>? _cachedCatalog;

  const RecipeNutritionReferenceRepo();

  Future<List<NutritionReferenceEntry>> loadCatalog() async {
    final cached = _cachedCatalog;
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final jsonText = await rootBundle.loadString(_catalogPath);
    final rawList = jsonDecode(jsonText) as List<dynamic>;
    final catalog = rawList
        .map(
          (entry) =>
              NutritionReferenceEntry.fromJson(entry as Map<String, dynamic>),
        )
        .toList(growable: false);
    _cachedCatalog = catalog;
    return catalog;
  }
}
