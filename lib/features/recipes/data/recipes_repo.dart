import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/recipe.dart';
import 'recipes_loader.dart';

final recipesRepoProvider = Provider<RecipesRepo>((ref) {
  return RecipesRepo(loader: const RecipesLoader());
});

class RecipesRepo {
  final RecipesLoader loader;
  List<Recipe>? _cache;

  RecipesRepo({required this.loader});

  Future<List<Recipe>> getAll({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) {
      return _cache!;
    }

    final recipes = await loader.loadRecipes();
    _cache = recipes;
    return recipes;
  }
}
