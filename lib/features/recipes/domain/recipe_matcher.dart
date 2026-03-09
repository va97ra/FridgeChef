import '../../fridge/domain/fridge_item.dart';
import '../../fridge/domain/product_catalog_entry.dart';
import '../../shelf/domain/shelf_item.dart';
import 'best_recipe_ranker.dart';
import 'cook_filter.dart';
import 'recipe.dart';
import 'recipe_match.dart';

export 'cook_filter.dart';

List<RecipeMatch> matchRecipes({
  required List<Recipe> recipes,
  required List<FridgeItem> fridgeItems,
  required List<ShelfItem> shelfItems,
  List<ProductCatalogEntry> catalog = const [],
  Set<CookFilter> filters = const {},
}) {
  return rankBestRecipes(
    recipes: recipes,
    fridgeItems: fridgeItems,
    shelfItems: shelfItems,
    catalog: catalog,
    filters: filters,
  );
}
