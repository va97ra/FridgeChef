import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/fridge/domain/fridge_item.dart';
import 'package:help_to_cook/features/fridge/domain/product_catalog_entry.dart';
import 'package:help_to_cook/features/recipes/domain/offline_recipe_idea_generator.dart';
import 'package:help_to_cook/features/recipes/domain/recipe.dart';
import 'package:help_to_cook/features/shelf/domain/pantry_catalog_entry.dart';
import 'package:help_to_cook/features/shelf/domain/shelf_item.dart';

void main() {
  test('builds local idea from eggs and matching add-ons', () {
    final ideas = buildOfflineRecipeIdeas(
      baseRecipes: const [],
      fridgeItems: const [
        FridgeItem(id: '1', name: 'Яйца', amount: 6, unit: Unit.pcs),
        FridgeItem(id: '2', name: 'Помидоры', amount: 3, unit: Unit.pcs),
        FridgeItem(id: '3', name: 'Сыр', amount: 200, unit: Unit.g),
      ],
      shelfItems: const [
        ShelfItem(id: 's1', name: 'Соль', inStock: true),
        ShelfItem(id: 's2', name: 'Паприка', inStock: true),
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
          id: 'paprika',
          name: 'Паприка',
          canonicalName: 'паприка',
          aliases: ['паприка'],
          category: 'spice',
          isStarter: true,
        ),
      ],
      catalog: const [
        ProductCatalogEntry(
          id: 'eggs',
          name: 'Яйца',
          canonicalName: 'яйцо',
          synonyms: ['яйцо'],
          defaultUnit: Unit.pcs,
        ),
        ProductCatalogEntry(
          id: 'tomato',
          name: 'Помидоры',
          canonicalName: 'помидор',
          synonyms: ['помидор', 'томат'],
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
          id: 'salt',
          name: 'Соль',
          canonicalName: 'соль',
          synonyms: [],
          defaultUnit: Unit.g,
        ),
        ProductCatalogEntry(
          id: 'paprika',
          name: 'Паприка',
          canonicalName: 'паприка',
          synonyms: [],
          defaultUnit: Unit.g,
        ),
      ],
    );

    expect(ideas, isNotEmpty);
    final skillet =
        ideas.firstWhere((recipe) => recipe.title.contains('Яичная сковорода'));
    expect(skillet.tags, contains('generated_local'));
    expect(
      skillet.ingredients.any(
        (ingredient) =>
            ingredient.name == 'Соль' || ingredient.name == 'Паприка',
      ),
      isTrue,
    );
    expect(
      skillet.steps.any((step) => step.toLowerCase().contains('доведи вкус')),
      isTrue,
    );
  });

  test('builds oven idea when inventory is rich enough', () {
    final ideas = buildOfflineRecipeIdeas(
      baseRecipes: const [],
      fridgeItems: const [
        FridgeItem(id: '1', name: 'Курица', amount: 500, unit: Unit.g),
        FridgeItem(id: '2', name: 'Картофель', amount: 6, unit: Unit.pcs),
        FridgeItem(id: '3', name: 'Морковь', amount: 2, unit: Unit.pcs),
        FridgeItem(id: '4', name: 'Лук', amount: 2, unit: Unit.pcs),
        FridgeItem(id: '5', name: 'Рис', amount: 300, unit: Unit.g),
        FridgeItem(id: '6', name: 'Сыр', amount: 220, unit: Unit.g),
        FridgeItem(id: '7', name: 'Грибы', amount: 180, unit: Unit.g),
        FridgeItem(id: '8', name: 'Яйца', amount: 3, unit: Unit.pcs),
      ],
      shelfItems: const [],
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
          id: 'oil',
          name: 'Масло',
          canonicalName: 'масло',
          aliases: ['масло'],
          category: 'oil',
          isStarter: true,
        ),
      ],
      catalog: const [
        ProductCatalogEntry(
          id: 'chicken',
          name: 'Курица',
          canonicalName: 'курица',
          synonyms: ['куриное мясо'],
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
          id: 'carrot',
          name: 'Морковь',
          canonicalName: 'морковь',
          synonyms: [],
          defaultUnit: Unit.pcs,
        ),
        ProductCatalogEntry(
          id: 'onion',
          name: 'Лук',
          canonicalName: 'лук',
          synonyms: [],
          defaultUnit: Unit.pcs,
        ),
        ProductCatalogEntry(
          id: 'rice',
          name: 'Рис',
          canonicalName: 'рис',
          synonyms: [],
          defaultUnit: Unit.g,
        ),
        ProductCatalogEntry(
          id: 'cheese',
          name: 'Сыр',
          canonicalName: 'сыр',
          synonyms: [],
          defaultUnit: Unit.g,
        ),
        ProductCatalogEntry(
          id: 'mushrooms',
          name: 'Грибы',
          canonicalName: 'грибы',
          synonyms: [],
          defaultUnit: Unit.g,
        ),
        ProductCatalogEntry(
          id: 'eggs',
          name: 'Яйца',
          canonicalName: 'яйцо',
          synonyms: ['яйцо'],
          defaultUnit: Unit.pcs,
        ),
      ],
    );

    expect(
      ideas.any((recipe) => recipe.tags.contains('oven')),
      isTrue,
    );
  });

  test('returns no ideas when inventory is too poor for templates', () {
    final ideas = buildOfflineRecipeIdeas(
      baseRecipes: const [
        Recipe(
          id: 'base',
          title: 'Просто вода',
          timeMin: 1,
          tags: ['quick'],
          servingsBase: 1,
          ingredients: [],
          steps: ['Ничего не делай'],
        ),
      ],
      fridgeItems: const [
        FridgeItem(id: '1', name: 'Соль', amount: 1, unit: Unit.pcs),
      ],
      shelfItems: const [],
      catalog: const [
        ProductCatalogEntry(
          id: 'salt',
          name: 'Соль',
          canonicalName: 'соль',
          synonyms: [],
          defaultUnit: Unit.g,
        ),
      ],
    );

    expect(ideas, isEmpty);
  });
}
