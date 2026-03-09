import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/fridge/domain/fridge_item.dart';
import 'package:help_to_cook/features/fridge/domain/product_catalog_entry.dart';
import 'package:help_to_cook/features/recipes/domain/ingredient_knowledge.dart';
import 'package:help_to_cook/features/recipes/domain/offline_chef_engine.dart';
import 'package:help_to_cook/features/recipes/domain/recipe.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_ingredient.dart';
import 'package:help_to_cook/features/shelf/domain/pantry_catalog_entry.dart';
import 'package:help_to_cook/features/shelf/domain/shelf_item.dart';

void main() {
  test('prioritizes near-expiry anchors first', () {
    final now = DateTime.now();
    final generated = const OfflineChefEngine().generate(
      _request(
        fridgeItems: [
          FridgeItem(
            id: 'egg',
            name: 'Яйца',
            amount: 6,
            unit: Unit.pcs,
            expiresAt: now.add(const Duration(days: 1)),
          ),
          FridgeItem(
            id: 'tomato',
            name: 'Помидоры',
            amount: 3,
            unit: Unit.pcs,
            expiresAt: now.add(const Duration(days: 2)),
          ),
          FridgeItem(
            id: 'cheese',
            name: 'Сыр',
            amount: 180,
            unit: Unit.g,
            expiresAt: now.add(const Duration(days: 4)),
          ),
          FridgeItem(
            id: 'chicken',
            name: 'Курица',
            amount: 500,
            unit: Unit.g,
            expiresAt: now.add(const Duration(days: 8)),
          ),
        ],
      ),
    );

    expect(generated, isNotEmpty);
    expect(generated.first.recipe.anchorIngredients, contains('Яйца'));
  });

  test('uses only pantry starters as implicit basics', () {
    final generated = const OfflineChefEngine().generate(
      _request(
        fridgeItems: const [
          FridgeItem(id: 'egg', name: 'Яйца', amount: 6, unit: Unit.pcs),
          FridgeItem(id: 'tomato', name: 'Помидоры', amount: 3, unit: Unit.pcs),
          FridgeItem(id: 'cheese', name: 'Сыр', amount: 180, unit: Unit.g),
        ],
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
            id: 'basil',
            name: 'Базилик',
            canonicalName: 'базилик',
            aliases: ['базилик'],
            category: 'herb',
          ),
        ],
      ),
    );

    expect(generated, isNotEmpty);
    final implicit = generated.first.recipe.implicitPantryItems;
    expect(implicit, isNotEmpty);
    expect(
      implicit.every((item) => item == 'Соль' || item == 'Черный перец'),
      isTrue,
    );
    expect(implicit, isNot(contains('Базилик')));
  });

  test('seed changes generated set without duplicates', () {
    final seedZero = const OfflineChefEngine().generate(
      _request(
        seed: 0,
        fridgeItems: const [
          FridgeItem(id: 'egg', name: 'Яйца', amount: 6, unit: Unit.pcs),
          FridgeItem(id: 'tomato', name: 'Помидоры', amount: 4, unit: Unit.pcs),
          FridgeItem(id: 'cheese', name: 'Сыр', amount: 220, unit: Unit.g),
          FridgeItem(id: 'potato', name: 'Картофель', amount: 5, unit: Unit.pcs),
          FridgeItem(id: 'chicken', name: 'Курица', amount: 450, unit: Unit.g),
          FridgeItem(id: 'rice', name: 'Рис', amount: 250, unit: Unit.g),
          FridgeItem(id: 'pasta', name: 'Макароны', amount: 300, unit: Unit.g),
          FridgeItem(id: 'mushrooms', name: 'Грибы', amount: 180, unit: Unit.g),
          FridgeItem(id: 'onion', name: 'Лук', amount: 2, unit: Unit.pcs),
          FridgeItem(id: 'carrot', name: 'Морковь', amount: 2, unit: Unit.pcs),
        ],
      ),
    );
    final seedOne = const OfflineChefEngine().generate(
      _request(
        seed: 1,
        fridgeItems: const [
          FridgeItem(id: 'egg', name: 'Яйца', amount: 6, unit: Unit.pcs),
          FridgeItem(id: 'tomato', name: 'Помидоры', amount: 4, unit: Unit.pcs),
          FridgeItem(id: 'cheese', name: 'Сыр', amount: 220, unit: Unit.g),
          FridgeItem(id: 'potato', name: 'Картофель', amount: 5, unit: Unit.pcs),
          FridgeItem(id: 'chicken', name: 'Курица', amount: 450, unit: Unit.g),
          FridgeItem(id: 'rice', name: 'Рис', amount: 250, unit: Unit.g),
          FridgeItem(id: 'pasta', name: 'Макароны', amount: 300, unit: Unit.g),
          FridgeItem(id: 'mushrooms', name: 'Грибы', amount: 180, unit: Unit.g),
          FridgeItem(id: 'onion', name: 'Лук', amount: 2, unit: Unit.pcs),
          FridgeItem(id: 'carrot', name: 'Морковь', amount: 2, unit: Unit.pcs),
        ],
      ),
    );

    expect(seedZero.map((item) => item.recipe.id).toSet().length, seedZero.length);
    expect(seedOne.map((item) => item.recipe.id).toSet().length, seedOne.length);
    expect(
      seedZero.map((item) => item.recipe.id).toList(),
      isNot(seedOne.map((item) => item.recipe.id).toList()),
    );
  });

  test('dedupes generated candidates against known recipes', () {
    final generated = const OfflineChefEngine().generate(
      _request(
        baseRecipes: const [
          Recipe(
            id: 'known',
            title: 'Домашний завтрак',
            timeMin: 12,
            tags: ['quick', 'breakfast'],
            servingsBase: 2,
            ingredients: [
              RecipeIngredient(name: 'Яйца', amount: 3, unit: Unit.pcs),
              RecipeIngredient(name: 'Помидоры', amount: 2, unit: Unit.pcs),
              RecipeIngredient(name: 'Сыр', amount: 180, unit: Unit.g),
            ],
            steps: ['Шаг 1', 'Шаг 2', 'Шаг 3'],
            chefProfile: 'skillet',
          ),
        ],
        fridgeItems: const [
          FridgeItem(id: 'egg', name: 'Яйца', amount: 6, unit: Unit.pcs),
          FridgeItem(id: 'tomato', name: 'Помидоры', amount: 3, unit: Unit.pcs),
          FridgeItem(id: 'cheese', name: 'Сыр', amount: 180, unit: Unit.g),
        ],
      ),
    );

    expect(generated, isEmpty);
  });

  test('rich inventory generation keeps strong pairing coverage', () {
    final generated = const OfflineChefEngine().generate(
      _request(
        shelfItems: const [
          ShelfItem(
            id: 's1',
            name: 'Соль',
            inStock: true,
            canonicalName: 'соль',
          ),
          ShelfItem(
            id: 's2',
            name: 'Черный перец',
            inStock: true,
            canonicalName: 'перец',
          ),
          ShelfItem(
            id: 's3',
            name: 'Оливковое масло',
            inStock: true,
            canonicalName: 'оливковое масло',
          ),
        ],
        fridgeItems: const [
          FridgeItem(id: 'egg', name: 'Яйца', amount: 6, unit: Unit.pcs),
          FridgeItem(id: 'tomato', name: 'Помидоры', amount: 4, unit: Unit.pcs),
          FridgeItem(id: 'cheese', name: 'Сыр', amount: 220, unit: Unit.g),
          FridgeItem(id: 'potato', name: 'Картофель', amount: 5, unit: Unit.pcs),
          FridgeItem(id: 'chicken', name: 'Курица', amount: 450, unit: Unit.g),
          FridgeItem(id: 'rice', name: 'Рис', amount: 250, unit: Unit.g),
          FridgeItem(id: 'pasta', name: 'Макароны', amount: 300, unit: Unit.g),
          FridgeItem(id: 'mushrooms', name: 'Грибы', amount: 180, unit: Unit.g),
          FridgeItem(id: 'onion', name: 'Лук', amount: 2, unit: Unit.pcs),
          FridgeItem(id: 'carrot', name: 'Морковь', amount: 2, unit: Unit.pcs),
        ],
      ),
    );

    expect(generated, isNotEmpty);

    for (final candidate in generated) {
      final canonicals = candidate.recipe.ingredients
          .where((ingredient) => ingredient.required)
          .map((ingredient) => toPairingKey(ingredient.name))
          .where((canonical) => canonical.isNotEmpty)
          .toSet()
          .toList();
      var strongPairs = 0;
      var forbiddenPairs = 0;

      for (var i = 0; i < canonicals.length; i++) {
        for (var j = i + 1; j < canonicals.length; j++) {
          final a = canonicals[i];
          final b = canonicals[j];
          if (pairedIngredientsFor(a).contains(b) ||
              pairedIngredientsFor(b).contains(a)) {
            strongPairs++;
          }
          if (forbiddenPairingsFor(a).contains(b) ||
              forbiddenPairingsFor(b).contains(a)) {
            forbiddenPairs++;
          }
        }
      }

      expect(strongPairs, greaterThan(0), reason: candidate.recipe.title);
      expect(forbiddenPairs, 0, reason: candidate.recipe.title);
    }
  });

  test('candidate reasons explain anchor urgency and pantry assumptions', () {
    final now = DateTime.now();
    final generated = const OfflineChefEngine().generate(
      _request(
        fridgeItems: [
          FridgeItem(
            id: 'egg',
            name: 'Яйца',
            amount: 6,
            unit: Unit.pcs,
            expiresAt: now.add(const Duration(days: 1)),
          ),
          const FridgeItem(
            id: 'tomato',
            name: 'Помидоры',
            amount: 3,
            unit: Unit.pcs,
          ),
          const FridgeItem(
            id: 'cheese',
            name: 'Сыр',
            amount: 180,
            unit: Unit.g,
          ),
        ],
      ),
    );

    expect(generated, isNotEmpty);
    expect(
      generated.first.reasons.any((reason) => reason.contains('шеф берёт в основу')),
      isTrue,
    );
    expect(
      generated.first.reasons.any((reason) => reason.contains('лучше пустить в дело сейчас')),
      isTrue,
    );
    expect(
      generated.first.reasons.any((reason) => reason.contains('из базовых вещей пригодятся')),
      isTrue,
    );
  });
}

OfflineChefRequest _request({
  List<Recipe> baseRecipes = const [],
  required List<FridgeItem> fridgeItems,
  List<ShelfItem> shelfItems = const [],
  List<PantryCatalogEntry>? pantryCatalog,
  int seed = 0,
}) {
  return OfflineChefRequest(
    baseRecipes: baseRecipes,
    fridgeItems: fridgeItems,
    shelfItems: shelfItems,
    productCatalog: const [
      ProductCatalogEntry(
        id: 'egg',
        name: 'Яйца',
        canonicalName: 'яйцо',
        synonyms: ['яйцо', 'яйца'],
        defaultUnit: Unit.pcs,
      ),
      ProductCatalogEntry(
        id: 'tomato',
        name: 'Помидоры',
        canonicalName: 'помидор',
        synonyms: ['помидор', 'томаты'],
        defaultUnit: Unit.pcs,
      ),
      ProductCatalogEntry(
        id: 'cheese',
        name: 'Сыр',
        canonicalName: 'сыр',
        synonyms: [],
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
        id: 'chicken',
        name: 'Курица',
        canonicalName: 'курица',
        synonyms: ['куриное мясо'],
        defaultUnit: Unit.g,
      ),
      ProductCatalogEntry(
        id: 'rice',
        name: 'Рис',
        canonicalName: 'рис',
        synonyms: [],
        defaultUnit: Unit.g,
      ),
      ProductCatalogEntry(
        id: 'pasta',
        name: 'Макароны',
        canonicalName: 'макароны',
        synonyms: ['паста'],
        defaultUnit: Unit.g,
      ),
      ProductCatalogEntry(
        id: 'mushrooms',
        name: 'Грибы',
        canonicalName: 'грибы',
        synonyms: ['гриб'],
        defaultUnit: Unit.g,
      ),
      ProductCatalogEntry(
        id: 'onion',
        name: 'Лук',
        canonicalName: 'лук',
        synonyms: [],
        defaultUnit: Unit.pcs,
      ),
      ProductCatalogEntry(
        id: 'carrot',
        name: 'Морковь',
        canonicalName: 'морковь',
        synonyms: [],
        defaultUnit: Unit.pcs,
      ),
    ],
    pantryCatalog: pantryCatalog ??
        const [
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
            id: 'oil',
            name: 'Масло',
            canonicalName: 'масло',
            aliases: ['масло'],
            category: 'oil',
            isStarter: true,
          ),
        ],
    seed: seed,
  );
}
