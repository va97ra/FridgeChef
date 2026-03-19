import 'dart:io';

import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/fridge/domain/fridge_item.dart';
import 'package:help_to_cook/features/fridge/domain/product_catalog_entry.dart';
import 'package:help_to_cook/features/recipes/domain/offline_chef_engine.dart';
import 'package:help_to_cook/features/recipes/domain/recipe.dart';
import 'package:help_to_cook/features/recipes/domain/chef_rules.dart';
import 'package:help_to_cook/features/shelf/domain/pantry_catalog_entry.dart';
import 'package:help_to_cook/features/shelf/domain/shelf_item.dart';

void main() {
  final engine = const OfflineChefEngine();

  final peaGenerated = engine.generate(
    OfflineChefRequest(
      baseRecipes: const <Recipe>[],
      fridgeItems: const [
        FridgeItem(id: 'peas', name: 'Горох', amount: 420, unit: Unit.g),
        FridgeItem(
          id: 'smoked_sausage',
          name: 'Копченая колбаса',
          amount: 260,
          unit: Unit.g,
        ),
        FridgeItem(id: 'potato', name: 'Картофель', amount: 4, unit: Unit.pcs),
        FridgeItem(id: 'onion', name: 'Лук', amount: 1, unit: Unit.pcs),
        FridgeItem(id: 'carrot', name: 'Морковь', amount: 1, unit: Unit.pcs),
        FridgeItem(id: 'dill', name: 'Укроп', amount: 12, unit: Unit.g),
      ],
      shelfItems: const <ShelfItem>[],
      productCatalog: const [
        ProductCatalogEntry(
          id: 'split_peas',
          name: 'Горох',
          canonicalName: 'горох',
          synonyms: ['горох', 'колотый горох'],
          defaultUnit: Unit.g,
        ),
        ProductCatalogEntry(
          id: 'sausage',
          name: 'Колбаса',
          canonicalName: 'колбаса',
          synonyms: ['колбаса', 'копченая колбаса'],
          defaultUnit: Unit.g,
        ),
        ProductCatalogEntry(
          id: 'potato',
          name: 'Картофель',
          canonicalName: 'картофель',
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
          id: 'carrot',
          name: 'Морковь',
          canonicalName: 'морковь',
          synonyms: [],
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
      ],
    ),
  );

  _logLine('PEA');
  for (final candidate in peaGenerated.take(10)) {
    _logLine(candidate.recipe.title);
    _logLine(candidate.recipe.steps);
  }

  final flatPea = assessChefRules(
    profile: DishProfile.soup,
    recipeCanonicals: const {'горох', 'колбаса', 'лук', 'морковь'},
    matchedCanonicals: const {'горох', 'колбаса', 'лук', 'морковь'},
    supportCanonicals: const {'соль'},
    displayByCanonical: const {
      'горох': 'Горох',
      'колбаса': 'Колбаса',
      'лук': 'Лук',
      'морковь': 'Морковь',
      'соль': 'Соль',
    },
    steps: const [
      'Подготовь горох, колбасу, лук и морковь.',
      'Влей воду и вари суп 18 минут.',
      'Подавай.',
    ],
  );
  final properPea = assessChefRules(
    profile: DishProfile.soup,
    title: 'Гороховый суп с копченостями',
    recipeCanonicals: const {
      'горох',
      'колбаса',
      'картофель',
      'лук',
      'морковь',
      'сметана',
      'укроп',
    },
    matchedCanonicals: const {
      'горох',
      'колбаса',
      'картофель',
      'лук',
      'морковь',
    },
    supportCanonicals: const {
      'соль',
      'перец',
      'лавровый лист',
      'сметана',
      'укроп',
    },
    displayByCanonical: const {
      'горох': 'Горох',
      'колбаса': 'Копченая колбаса',
      'картофель': 'Картофель',
      'лук': 'Лук',
      'морковь': 'Морковь',
      'сметана': 'Сметана',
      'укроп': 'Укроп',
      'лавровый лист': 'Лавровый лист',
      'соль': 'Соль',
      'перец': 'Перец',
    },
    steps: const [
      'Промой горох, картофель пока держи отдельно, сначала мягко прогрей лук и морковь 4-5 минут и затем добавь копченую колбасу еще на 1-2 минуты.',
      'Влей воду, добавь горох и вари гороховый суп 35-45 минут на спокойном огне, а картофель положи на последние 12-15 минут.',
      'Сними с огня, подай со сметаной и укропом.',
    ],
  );
  _logLine('PEA SCORES');
  _logLine(
    'flat total=${flatPea.score} structure=${flatPea.structureScore} technique=${flatPea.techniqueScore} balance=${flatPea.balanceScore} flavor=${flatPea.flavorScore} warnings=${flatPea.warnings}',
  );
  _logLine(
    'proper total=${properPea.score} structure=${properPea.structureScore} technique=${properPea.techniqueScore} balance=${properPea.balanceScore} flavor=${properPea.flavorScore} warnings=${properPea.warnings}',
  );

  final svekolnikGenerated = engine.generate(
    OfflineChefRequest(
      baseRecipes: const <Recipe>[],
      fridgeItems: const [
        FridgeItem(id: 'beet', name: 'Свекла', amount: 3, unit: Unit.pcs),
        FridgeItem(id: 'kefir', name: 'Кефир', amount: 900, unit: Unit.ml),
        FridgeItem(id: 'cucumber', name: 'Огурцы', amount: 3, unit: Unit.pcs),
        FridgeItem(id: 'potato', name: 'Картофель', amount: 4, unit: Unit.pcs),
        FridgeItem(id: 'egg', name: 'Яйца', amount: 3, unit: Unit.pcs),
        FridgeItem(id: 'dill', name: 'Укроп', amount: 12, unit: Unit.g),
      ],
      shelfItems: const <ShelfItem>[],
      productCatalog: const [
        ProductCatalogEntry(
          id: 'beet',
          name: 'Свекла',
          canonicalName: 'свекла',
          synonyms: ['свекла', 'свёкла'],
          defaultUnit: Unit.pcs,
        ),
        ProductCatalogEntry(
          id: 'kefir',
          name: 'Кефир',
          canonicalName: 'кефир',
          synonyms: ['кефир'],
          defaultUnit: Unit.ml,
        ),
        ProductCatalogEntry(
          id: 'cucumber',
          name: 'Огурцы',
          canonicalName: 'огурец',
          synonyms: ['огурец'],
          defaultUnit: Unit.pcs,
        ),
        ProductCatalogEntry(
          id: 'potato',
          name: 'Картофель',
          canonicalName: 'картофель',
          synonyms: [],
          defaultUnit: Unit.pcs,
        ),
        ProductCatalogEntry(
          id: 'egg',
          name: 'Яйца',
          canonicalName: 'яйцо',
          synonyms: ['яйцо', 'яйца'],
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
    ),
  );

  _logLine('SVEKOLNIK');
  for (final candidate in svekolnikGenerated.take(10)) {
    _logLine(candidate.recipe.title);
    _logLine(candidate.recipe.steps);
  }
}

void _logLine(Object? message) {
  stdout.writeln(message);
}
