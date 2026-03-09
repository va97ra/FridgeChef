import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/fridge/data/fridge_repo.dart';
import 'package:help_to_cook/features/fridge/data/user_product_memory_repo.dart';
import 'package:help_to_cook/features/fridge/domain/fridge_item.dart';
import 'package:help_to_cook/features/fridge/domain/product_catalog_entry.dart';
import 'package:help_to_cook/features/recipes/domain/best_recipe_ranker.dart';
import 'package:help_to_cook/features/recipes/domain/offline_chef_engine.dart';
import 'package:help_to_cook/features/recipes/domain/recipe.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_ingredient.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_match.dart';
import 'package:help_to_cook/features/recipes/domain/taste_profile.dart';
import 'package:help_to_cook/features/recipes/presentation/providers.dart';
import 'package:help_to_cook/features/shelf/data/shelf_repo.dart';
import 'package:help_to_cook/features/shelf/domain/pantry_catalog_entry.dart';
import 'package:help_to_cook/features/shelf/domain/shelf_item.dart';

void main() {
  test('recipeMatchesProvider ranks base and chef ideas in one common list',
      () async {
    final fridgeItems = [
      FridgeItem(
        id: 'eggs',
        name: 'Яйца',
        amount: 4,
        unit: Unit.pcs,
        expiresAt: DateTime(2026, 3, 10),
      ),
      const FridgeItem(
        id: 'tomatoes',
        name: 'Помидоры',
        amount: 3,
        unit: Unit.pcs,
      ),
      const FridgeItem(
        id: 'onion',
        name: 'Лук',
        amount: 1,
        unit: Unit.pcs,
      ),
      FridgeItem(
        id: 'fish',
        name: 'Рыба',
        amount: 500,
        unit: Unit.g,
        expiresAt: DateTime(2026, 3, 10),
      ),
      const FridgeItem(
        id: 'potatoes',
        name: 'Картофель',
        amount: 700,
        unit: Unit.g,
      ),
      const FridgeItem(
        id: 'lemon',
        name: 'Лимон',
        amount: 2,
        unit: Unit.pcs,
      ),
      const FridgeItem(
        id: 'dill',
        name: 'Укроп',
        amount: 30,
        unit: Unit.g,
      ),
    ];
    const shelfItems = [
      ShelfItem(id: 'salt', name: 'Соль', inStock: true),
      ShelfItem(id: 'pepper', name: 'Перец', inStock: true),
      ShelfItem(id: 'oil', name: 'Масло', inStock: true),
    ];
    final container = ProviderContainer(
      overrides: [
        recipesProvider.overrideWith((ref) async => [_strongBaseRecipe]),
        productCatalogProvider.overrideWith((ref) async => _catalog),
        pantryCatalogProvider.overrideWith((ref) async => _pantryCatalog),
        tasteProfileProvider.overrideWith((ref) => const TasteProfile.empty()),
        fridgeRepoProvider.overrideWithValue(
          _StaticFridgeRepo(fridgeItems),
        ),
        userProductMemoryRepoProvider
            .overrideWithValue(const _NoopUserProductMemoryRepo()),
        shelfRepoProvider.overrideWithValue(_StaticShelfRepo(shelfItems)),
      ],
    );
    addTearDown(container.dispose);

    await container.read(recipesProvider.future);
    await container.read(productCatalogProvider.future);
    await container.read(pantryCatalogProvider.future);

    final matches = container.read(recipeMatchesProvider);
    final expectedGenerated = const OfflineChefEngine().generate(
      OfflineChefRequest(
        baseRecipes: const [_strongBaseRecipe],
        fridgeItems: fridgeItems,
        shelfItems: shelfItems,
        productCatalog: _catalog,
        pantryCatalog: _pantryCatalog,
      ),
    );
    final expectedMatches = rankBestRecipes(
      recipes: const [_strongBaseRecipe],
      generatedRecipes: expectedGenerated
          .map((candidate) => candidate.recipe)
          .toList(growable: false),
      fridgeItems: fridgeItems,
      shelfItems: shelfItems,
      catalog: _catalog,
    );

    expect(
      expectedMatches.any((match) => match.source == RecipeMatchSource.base),
      isTrue,
    );
    expect(
      expectedMatches.any((match) => match.source == RecipeMatchSource.generated),
      isTrue,
    );
    final firstBaseIndex = expectedMatches.indexWhere(
      (match) => match.source == RecipeMatchSource.base,
    );
    expect(firstBaseIndex, greaterThan(0));
    expect(
      expectedMatches
          .skip(firstBaseIndex + 1)
          .any((match) => match.source == RecipeMatchSource.generated),
      isTrue,
    );
    expect(
      matches.map((match) => '${match.source.name}:${match.recipe.id}').toList(),
      expectedMatches
          .map((match) => '${match.source.name}:${match.recipe.id}')
          .toList(),
    );
  });

  test('recipeMatchesProvider still returns chef ideas with empty base recipes',
      () async {
    final container = ProviderContainer(
      overrides: [
        recipesProvider.overrideWith((ref) async => const <Recipe>[]),
        productCatalogProvider.overrideWith((ref) async => _catalog),
        pantryCatalogProvider.overrideWith((ref) async => _pantryCatalog),
        tasteProfileProvider.overrideWith((ref) => const TasteProfile.empty()),
        fridgeRepoProvider.overrideWithValue(
          _StaticFridgeRepo(const [
            FridgeItem(id: 'eggs', name: 'Яйца', amount: 6, unit: Unit.pcs),
            FridgeItem(
              id: 'tomatoes',
              name: 'Помидоры',
              amount: 3,
              unit: Unit.pcs,
            ),
            FridgeItem(id: 'cheese', name: 'Сыр', amount: 150, unit: Unit.g),
          ]),
        ),
        userProductMemoryRepoProvider
            .overrideWithValue(const _NoopUserProductMemoryRepo()),
        shelfRepoProvider.overrideWithValue(
          _StaticShelfRepo(const [
            ShelfItem(id: 'salt', name: 'Соль', inStock: true),
            ShelfItem(id: 'pepper', name: 'Перец', inStock: true),
            ShelfItem(id: 'oil', name: 'Масло', inStock: true),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(recipesProvider.future);
    await container.read(productCatalogProvider.future);
    await container.read(pantryCatalogProvider.future);

    final matches = container.read(recipeMatchesProvider);

    expect(matches, isNotEmpty);
    expect(matches.first.source, RecipeMatchSource.generated);
    expect(
      matches.any((match) => match.source == RecipeMatchSource.generated),
      isTrue,
    );
  });
}

const _strongBaseRecipe = Recipe(
  id: 'base_bake_fish',
  title: 'Рыба с лимоном и картофелем',
  timeMin: 32,
  tags: ['oven', 'bake'],
  servingsBase: 2,
  ingredients: [
    RecipeIngredient(name: 'Рыба', amount: 350, unit: Unit.g),
    RecipeIngredient(name: 'Картофель', amount: 400, unit: Unit.g),
    RecipeIngredient(name: 'Лимон', amount: 1, unit: Unit.pcs),
    RecipeIngredient(name: 'Укроп', amount: 20, unit: Unit.g),
  ],
  steps: [
    'Сбрызни рыбу лимоном и маслом.',
    'Накрой форму и запекай вместе с картофелем до готовности.',
    'Дай рыбе минуту отдохнуть, добавь укроп и подай.',
  ],
);

const _catalog = <ProductCatalogEntry>[
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
    synonyms: ['помидор', 'помидоры'],
    defaultUnit: Unit.pcs,
  ),
  ProductCatalogEntry(
    id: 'cheese',
    name: 'Сыр',
    canonicalName: 'сыр',
    synonyms: ['сыр'],
    defaultUnit: Unit.g,
  ),
  ProductCatalogEntry(
    id: 'fish',
    name: 'Рыба',
    canonicalName: 'рыба',
    synonyms: ['рыба'],
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
    id: 'potato',
    name: 'Картофель',
    canonicalName: 'картофель',
    synonyms: ['картофель', 'картошка'],
    defaultUnit: Unit.g,
  ),
  ProductCatalogEntry(
    id: 'lemon',
    name: 'Лимон',
    canonicalName: 'лимон',
    synonyms: ['лимон'],
    defaultUnit: Unit.pcs,
  ),
  ProductCatalogEntry(
    id: 'dill',
    name: 'Укроп',
    canonicalName: 'укроп',
    synonyms: ['укроп'],
    defaultUnit: Unit.g,
  ),
];

const _pantryCatalog = <PantryCatalogEntry>[
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
    name: 'Перец',
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
    supportCanonicals: ['жирная связка'],
  ),
];

class _StaticFridgeRepo extends FridgeRepo {
  final List<FridgeItem> _items;

  _StaticFridgeRepo(List<FridgeItem> items)
      : _items = List<FridgeItem>.from(items),
        super(boxName: 'ignored');

  @override
  List<FridgeItem> getAll() => List<FridgeItem>.from(_items);
}

class _StaticShelfRepo extends ShelfRepo {
  final List<ShelfItem> _items;

  _StaticShelfRepo(List<ShelfItem> items)
      : _items = List<ShelfItem>.from(items),
        super(boxName: 'ignored');

  @override
  List<ShelfItem> getAll() => List<ShelfItem>.from(_items);
}

class _NoopUserProductMemoryRepo extends UserProductMemoryRepo {
  const _NoopUserProductMemoryRepo();

  @override
  Future<void> recordProduct({
    required String name,
    required Unit unit,
    required double amount,
    String? productId,
  }) async {}
}
