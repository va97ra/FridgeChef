import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/fridge/domain/fridge_item.dart';
import 'package:help_to_cook/features/fridge/domain/product_catalog_entry.dart';
import 'package:help_to_cook/features/recipes/domain/chef_dish_validator.dart';
import 'package:help_to_cook/features/recipes/domain/chef_rules.dart';
import 'package:help_to_cook/features/recipes/domain/offline_chef_blueprints.dart';
import 'package:help_to_cook/features/recipes/domain/offline_chef_engine.dart';
import 'package:help_to_cook/features/recipes/domain/recipe.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_ingredient.dart';
import 'package:help_to_cook/features/recipes/domain/taste_profile.dart';
import 'package:help_to_cook/features/shelf/domain/pantry_catalog_entry.dart';

void main() {
  _debugGreenShchi();
  _debugStewedCabbage();
}

void _debugGreenShchi() {
  const engine = OfflineChefEngine();
  final generated = engine.generate(
    OfflineChefRequest(
      baseRecipes: const [],
      shelfItems: const [],
      filters: const {},
      tasteProfile: const TasteProfile.empty(),
      seed: 0,
      pantryCatalog: const [
        PantryCatalogEntry(
          id: 'salt',
          name: 'Соль',
          canonicalName: 'соль',
          aliases: ['соль'],
          category: 'basic',
          isStarter: true,
        ),
        PantryCatalogEntry(
          id: 'pepper',
          name: 'Черный перец',
          canonicalName: 'перец',
          aliases: ['перец'],
          category: 'spice',
          isStarter: true,
        ),
        PantryCatalogEntry(
          id: 'sour_cream',
          name: 'Сметана',
          canonicalName: 'сметана',
          aliases: ['сметана'],
          category: 'dairy',
          isStarter: true,
        ),
      ],
      productCatalog: const [
        ProductCatalogEntry(
          id: 'sorrel',
          name: 'Щавель',
          canonicalName: 'щавель',
          synonyms: ['щавель'],
          defaultUnit: Unit.g,
        ),
        ProductCatalogEntry(
          id: 'potato',
          name: 'Картофель',
          canonicalName: 'картофель',
          synonyms: ['картошка'],
          defaultUnit: Unit.pcs,
        ),
        ProductCatalogEntry(
          id: 'egg',
          name: 'Яйца',
          canonicalName: 'яйцо',
          synonyms: ['яйца', 'яйцо'],
          defaultUnit: Unit.pcs,
        ),
        ProductCatalogEntry(
          id: 'onion',
          name: 'Лук',
          canonicalName: 'лук',
          synonyms: ['лук'],
          defaultUnit: Unit.pcs,
        ),
        ProductCatalogEntry(
          id: 'carrot',
          name: 'Морковь',
          canonicalName: 'морковь',
          synonyms: ['морковь'],
          defaultUnit: Unit.pcs,
        ),
        ProductCatalogEntry(
          id: 'dill',
          name: 'Укроп',
          canonicalName: 'укроп',
          synonyms: ['укроп'],
          defaultUnit: Unit.g,
        ),
      ],
      fridgeItems: const [
        FridgeItem(id: 'sorrel', name: 'Щавель', amount: 160, unit: Unit.g),
        FridgeItem(
          id: 'potato',
          name: 'Картофель',
          amount: 5,
          unit: Unit.pcs,
        ),
        FridgeItem(id: 'eggs', name: 'Яйца', amount: 4, unit: Unit.pcs),
        FridgeItem(id: 'onion', name: 'Лук', amount: 1, unit: Unit.pcs),
        FridgeItem(id: 'carrot', name: 'Морковь', amount: 1, unit: Unit.pcs),
        FridgeItem(id: 'dill', name: 'Укроп', amount: 20, unit: Unit.g),
      ],
    ),
  );

  print('GREEN GENERATED');
  for (final candidate in generated) {
    print('${candidate.recipe.title} | ${candidate.priorityScore}');
    print(candidate.recipe.ingredients.map((e) => e.name).join(', '));
  }

  final recipe = Recipe(
    id: 'green_debug',
    title: 'Щавелевые щи: Щавель, Яйца',
    description: '',
    timeMin: 34,
    tags: const ['russian_classic'],
    servingsBase: 3,
    ingredients: const [
      RecipeIngredient(name: 'Щавель', amount: 160, unit: Unit.g),
      RecipeIngredient(name: 'Яйца', amount: 3, unit: Unit.pcs),
      RecipeIngredient(name: 'Картофель', amount: 4, unit: Unit.pcs),
      RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
      RecipeIngredient(name: 'Морковь', amount: 1, unit: Unit.pcs),
      RecipeIngredient(name: 'Соль', amount: 4, unit: Unit.g, required: false),
      RecipeIngredient(
        name: 'Черный перец',
        amount: 2,
        unit: Unit.g,
        required: false,
      ),
      RecipeIngredient(
        name: 'Сметана',
        amount: 60,
        unit: Unit.g,
        required: false,
      ),
    ],
    steps: const [
      'Подготовь щавель, картофель, лук и морковь, а яйца держи для более сытной основы.',
      'Влей воду и вари овощную основу 16-18 минут, затем добавь яйца на оставшееся время, а в последние 2-3 минуты добавь щавель, чтобы суп сохранил свежую кислоту.',
      'В конце доведи щавелевые щи через соль и черный перец и подай со сметаной, затем дай супу постоять 2-3 минуты.',
    ],
    source: RecipeSource.generatedDraft,
    chefProfile: DishProfile.soup.name,
    anchorIngredients: const [],
    implicitPantryItems: const [],
  );
  final canonicals = {
    'щавель',
    'яйцо',
    'картофель',
    'лук',
    'морковь',
    'соль',
    'перец',
    'сметана',
  };
  final rules = assessChefRules(
    profile: DishProfile.soup,
    title: recipe.title,
    recipeCanonicals: canonicals,
    matchedCanonicals: canonicals,
    supportCanonicals: const {'соль', 'перец', 'сметана', 'укроп'},
    displayByCanonical: const {
      'щавель': 'Щавель',
      'яйцо': 'Яйца',
      'картофель': 'Картофель',
      'лук': 'Лук',
      'морковь': 'Морковь',
      'соль': 'Соль',
      'перец': 'Черный перец',
      'сметана': 'Сметана',
      'укроп': 'Укроп',
    },
    steps: recipe.steps,
  );
  final validation = validateChefDish(
    blueprint: chefBlueprints.firstWhere((b) => b.id == 'green_shchi_sorrel'),
    recipe: recipe,
    recipeCanonicals: canonicals,
  );
  print(
    'GREEN RULES score=${rules.score} flavor=${rules.flavorScore} tech=${rules.techniqueScore} balance=${rules.balanceScore}',
  );
  print('GREEN WARNINGS ${rules.warnings}');
  print('GREEN VALID ${validation.isValid} ${validation.violations}');
}

void _debugStewedCabbage() {
  const engine = OfflineChefEngine();
  final generated = engine.generate(
    OfflineChefRequest(
      baseRecipes: const [],
      shelfItems: const [],
      filters: const {},
      tasteProfile: const TasteProfile.empty(),
      seed: 0,
      pantryCatalog: const [
        PantryCatalogEntry(
          id: 'salt',
          name: 'Соль',
          canonicalName: 'соль',
          aliases: ['соль'],
          category: 'basic',
          isStarter: true,
        ),
        PantryCatalogEntry(
          id: 'pepper',
          name: 'Черный перец',
          canonicalName: 'перец',
          aliases: ['перец'],
          category: 'spice',
          isStarter: true,
        ),
        PantryCatalogEntry(
          id: 'bay_leaf',
          name: 'Лавровый лист',
          canonicalName: 'лавровый лист',
          aliases: ['лавровый лист'],
          category: 'spice',
          isStarter: true,
        ),
        PantryCatalogEntry(
          id: 'tomato_paste',
          name: 'Томатная паста',
          canonicalName: 'томатная паста',
          aliases: ['томатная паста'],
          category: 'sauce',
          isStarter: true,
        ),
      ],
      productCatalog: const [
        ProductCatalogEntry(
          id: 'cabbage',
          name: 'Капуста',
          canonicalName: 'капуста',
          synonyms: ['капуста'],
          defaultUnit: Unit.g,
        ),
        ProductCatalogEntry(
          id: 'sausage',
          name: 'Колбаса',
          canonicalName: 'колбаса',
          synonyms: ['колбаса'],
          defaultUnit: Unit.g,
        ),
        ProductCatalogEntry(
          id: 'onion',
          name: 'Лук',
          canonicalName: 'лук',
          synonyms: ['лук'],
          defaultUnit: Unit.pcs,
        ),
        ProductCatalogEntry(
          id: 'carrot',
          name: 'Морковь',
          canonicalName: 'морковь',
          synonyms: ['морковь'],
          defaultUnit: Unit.pcs,
        ),
      ],
      fridgeItems: const [
        FridgeItem(id: 'cabbage', name: 'Капуста', amount: 900, unit: Unit.g),
        FridgeItem(id: 'sausage', name: 'Колбаса', amount: 320, unit: Unit.g),
        FridgeItem(id: 'onion', name: 'Лук', amount: 2, unit: Unit.pcs),
        FridgeItem(id: 'carrot', name: 'Морковь', amount: 2, unit: Unit.pcs),
      ],
    ),
  );

  print('CABBAGE GENERATED');
  for (final candidate in generated) {
    print('${candidate.recipe.title} | ${candidate.priorityScore}');
    print(candidate.recipe.ingredients.map((e) => e.name).join(', '));
  }
}
