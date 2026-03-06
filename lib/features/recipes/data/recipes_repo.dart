import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/recipe.dart';
import 'recipes_loader.dart';
import 'user_recipes_repo.dart';

final recipesRepoProvider = Provider<RecipesRepo>((ref) {
  final userRecipesRepo = ref.watch(userRecipesRepoProvider);
  return RecipesRepo(
    loader: const RecipesLoader(),
    userRecipesRepo: userRecipesRepo,
  );
});

class RecipesRepo {
  final RecipesLoader loader;
  final UserRecipesRepo userRecipesRepo;
  List<Recipe>? _assetCache;

  RecipesRepo({
    required this.loader,
    required this.userRecipesRepo,
  });

  Future<List<Recipe>> getAll({bool forceRefresh = false}) async {
    if (forceRefresh || _assetCache == null) {
      _assetCache = await loader.loadRecipes();
    }

    final userRecipes = await userRecipesRepo.getAllUserRecipes();
    return [
      ...?_assetCache,
      ...userRecipes,
    ];
  }
}
