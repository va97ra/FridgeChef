import '../../fridge/domain/fridge_item.dart';
import '../../fridge/domain/product_catalog_entry.dart';
import '../../shelf/domain/pantry_catalog_entry.dart';
import '../../shelf/domain/shelf_item.dart';
import 'offline_chef_engine.dart';
import 'recipe.dart';

List<Recipe> buildOfflineRecipeIdeas({
  required List<Recipe> baseRecipes,
  required List<FridgeItem> fridgeItems,
  required List<ShelfItem> shelfItems,
  required List<ProductCatalogEntry> catalog,
  List<PantryCatalogEntry> pantryCatalog = const [],
  int seed = 0,
}) {
  final engine = const OfflineChefEngine();
  final generated = engine.generate(
    OfflineChefRequest(
      baseRecipes: baseRecipes,
      fridgeItems: fridgeItems,
      shelfItems: shelfItems,
      productCatalog: catalog,
      pantryCatalog: pantryCatalog,
      seed: seed,
    ),
  );
  return generated.map((candidate) => candidate.recipe).toList();
}
