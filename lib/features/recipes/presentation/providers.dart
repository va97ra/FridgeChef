import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../fridge/data/product_catalog_repo.dart';
import '../../fridge/presentation/providers.dart';
import '../../shelf/data/pantry_catalog_repo.dart';
import '../../shelf/presentation/providers.dart';
import '../data/recipes_repo.dart';
import '../data/recipe_feedback_repo.dart';
import '../domain/best_recipe_ranker.dart';
import '../domain/cook_filter.dart';
import '../domain/offline_chef_engine.dart';
import '../domain/recipe.dart';
import '../domain/recipe_match.dart';
import '../domain/taste_profile.dart';

final recipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final repo = ref.watch(recipesRepoProvider);
  return repo.getAll();
});

final productCatalogProvider = FutureProvider((ref) async {
  return ref.watch(productCatalogRepoProvider).loadCatalog();
});
final pantryCatalogProvider = FutureProvider((ref) async {
  return ref.watch(pantryCatalogRepoProvider).loadCatalog();
});

final cookFiltersProvider = StateProvider<Set<CookFilter>>((ref) => {});
final cookQueryProvider = StateProvider<String>((ref) => '');
final chefGenerationSeedProvider = StateProvider<int>((ref) => 0);

class RecipeFeedbackNotifier
    extends StateNotifier<Map<String, RecipeFeedbackVote>> {
  final RecipeFeedbackRepo _repo;

  RecipeFeedbackNotifier(this._repo) : super(const {}) {
    _load();
  }

  Future<void> _load() async {
    state = await _repo.loadAll();
  }

  Future<void> setVote(String recipeId, RecipeFeedbackVote? vote) async {
    await _repo.setVote(recipeId, vote);
    await _load();
  }
}

final recipeFeedbackProvider = StateNotifierProvider<RecipeFeedbackNotifier,
    Map<String, RecipeFeedbackVote>>((ref) {
  return RecipeFeedbackNotifier(ref.watch(recipeFeedbackRepoProvider));
});

final tasteProfileProvider = Provider<TasteProfile>((ref) {
  final feedback = ref.watch(recipeFeedbackProvider);
  final recipes = ref.watch(recipesProvider).valueOrNull;
  final catalog = ref.watch(productCatalogProvider).valueOrNull;

  if (recipes == null || catalog == null) {
    return TasteProfile(recipeVotes: feedback);
  }

  return buildTasteProfile(
    feedbackByRecipeId: feedback,
    recipes: recipes,
    catalog: catalog,
  );
});

final recipeMatchesProvider = Provider<List<RecipeMatch>>((ref) {
  final recipes = ref.watch(recipesProvider).valueOrNull;
  final catalog = ref.watch(productCatalogProvider).valueOrNull;
  final pantryCatalog = ref.watch(pantryCatalogProvider).valueOrNull;
  final fridgeItems = ref.watch(fridgeListProvider);
  final shelfItems = ref.watch(shelfListProvider);
  final filters = ref.watch(cookFiltersProvider);
  final query = ref.watch(cookQueryProvider).trim().toLowerCase();
  final tasteProfile = ref.watch(tasteProfileProvider);
  final seed = ref.watch(chefGenerationSeedProvider);

  if (recipes == null ||
      catalog == null ||
      pantryCatalog == null ||
      recipes.isEmpty) {
    return const [];
  }

  final generatedRecipes = const OfflineChefEngine()
      .generate(
        OfflineChefRequest(
          baseRecipes: recipes,
          fridgeItems: fridgeItems,
          shelfItems: shelfItems,
          productCatalog: catalog,
          pantryCatalog: pantryCatalog,
          filters: filters,
          tasteProfile: tasteProfile,
          seed: seed,
        ),
      )
      .map((candidate) => candidate.recipe)
      .toList();

  final generatedMatches = generatedRecipes.isEmpty
      ? const <RecipeMatch>[]
      : rankBestRecipes(
          recipes: const [],
          generatedRecipes: generatedRecipes,
          fridgeItems: fridgeItems,
          shelfItems: shelfItems,
          catalog: catalog,
          filters: filters,
          tasteProfile: tasteProfile,
        );
  final baseMatches = rankBestRecipes(
    recipes: recipes,
    fridgeItems: fridgeItems,
    shelfItems: shelfItems,
    catalog: catalog,
    filters: filters,
    tasteProfile: tasteProfile,
  );
  final matches = generatedMatches.isEmpty
      ? baseMatches
      : [
          ...generatedMatches,
          ...baseMatches,
        ];

  if (query.isEmpty) {
    return matches;
  }

  return matches.where((match) => _matchesQuery(match, query)).toList();
});

bool _matchesQuery(RecipeMatch match, String query) {
  if (match.recipe.title.toLowerCase().contains(query)) {
    return true;
  }

  final tags = match.recipe.tags.map((tag) => tag.toLowerCase());
  if (tags.any((tag) => tag.contains(query))) {
    return true;
  }

  if (match.why.any((reason) => reason.toLowerCase().contains(query))) {
    return true;
  }

  return match.recipe.ingredients.any(
    (ingredient) => ingredient.name.toLowerCase().contains(query),
  );
}
