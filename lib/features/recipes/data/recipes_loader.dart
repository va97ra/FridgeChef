import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../domain/recipe.dart';

class RecipesLoader {
  const RecipesLoader();

  Future<List<Recipe>> loadRecipes() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/recipes/recipes.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Recipe.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading recipes: $e');
      return [];
    }
  }
}
