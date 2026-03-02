import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../fridge/presentation/providers.dart';
import '../../shelf/presentation/providers.dart';
import '../data/recipes_repo.dart';
import '../domain/recipe.dart';
import '../domain/recipe_match.dart';
import '../domain/recipe_matcher.dart';

final recipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final repo = ref.watch(recipesRepoProvider);
  return repo.getAll();
});

final cookFiltersProvider = StateProvider<Set<CookFilter>>((ref) => {});
final cookQueryProvider = StateProvider<String>((ref) => '');

final recipeMatchesProvider = Provider<List<RecipeMatch>>((ref) {
  final recipesAsync = ref.watch(recipesProvider);
  final fridgeItems = ref.watch(fridgeListProvider);
  final shelfItems = ref.watch(shelfListProvider);
  final filters = ref.watch(cookFiltersProvider);
  final query = ref.watch(cookQueryProvider).trim().toLowerCase();

  return recipesAsync.maybeWhen(
    data: (recipes) {
      if (recipes.isEmpty) {
        return [];
      }

      final matches = matchRecipes(
        recipes: recipes,
        fridgeItems: fridgeItems,
        shelfItems: shelfItems,
        filters: filters,
      );

      if (query.isEmpty) {
        return matches;
      }

      return matches.where((match) {
        final title = match.recipe.title.toLowerCase();
        if (title.contains(query)) {
          return true;
        }

        final tags = match.recipe.tags.map((tag) => tag.toLowerCase());
        if (tags.any((tag) => tag.contains(query))) {
          return true;
        }

        return match.recipe.ingredients.any(
          (ingredient) => ingredient.name.toLowerCase().contains(query),
        );
      }).toList();
    },
    orElse: () => [],
  );
});
