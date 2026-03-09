import 'dart:convert';
import 'dart:io';

import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/fridge/domain/fridge_item.dart';
import 'package:help_to_cook/features/fridge/domain/product_catalog_entry.dart';
import 'package:help_to_cook/features/recipes/domain/best_recipe_ranker.dart';
import 'package:help_to_cook/features/recipes/domain/offline_chef_engine.dart';
import 'package:help_to_cook/features/recipes/domain/recipe.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_match.dart';
import 'package:help_to_cook/features/shelf/domain/pantry_catalog_entry.dart';
import 'package:help_to_cook/features/shelf/domain/shelf_item.dart';

class BenchmarkScenario {
  final String id;
  final String label;
  final List<String> expectedTitleFragments;
  final List<FridgeItem> fridgeItems;
  final List<String> shelfCanonicals;

  const BenchmarkScenario({
    required this.id,
    required this.label,
    required this.expectedTitleFragments,
    required this.fridgeItems,
    this.shelfCanonicals = const [],
  });
}

void main() {
  final products = _loadProducts();
  final pantry = _loadPantry();
  final recipes = _loadRecipes();
  final engine = const OfflineChefEngine();
  final now = DateTime(2026, 3, 9, 12);

  final scenarios = <BenchmarkScenario>[
    BenchmarkScenario(
      id: 'olivier_holiday',
      label: 'Праздничный оливье',
      expectedTitleFragments: const ['оливье'],
      shelfCanonicals: const ['соль', 'перец', 'майонез'],
      fridgeItems: const [
        FridgeItem(id: 'potato', name: 'Картофель', amount: 5, unit: Unit.pcs),
        FridgeItem(id: 'egg', name: 'Яйца', amount: 6, unit: Unit.pcs),
        FridgeItem(id: 'carrot', name: 'Морковь', amount: 2, unit: Unit.pcs),
        FridgeItem(
          id: 'cucumber',
          name: 'Соленые огурцы',
          amount: 3,
          unit: Unit.pcs,
        ),
        FridgeItem(
          id: 'peas',
          name: 'Зеленый горошек',
          amount: 180,
          unit: Unit.g,
        ),
        FridgeItem(
          id: 'sausage',
          name: 'Докторская колбаса',
          amount: 240,
          unit: Unit.g,
        ),
      ],
    ),
    BenchmarkScenario(
      id: 'vinegret_root',
      label: 'Корнеплодный винегрет',
      expectedTitleFragments: const ['винегрет'],
      shelfCanonicals: const ['соль', 'перец', 'масло', 'укроп'],
      fridgeItems: const [
        FridgeItem(id: 'beetroot', name: 'Свекла', amount: 2, unit: Unit.pcs),
        FridgeItem(id: 'potato', name: 'Картофель', amount: 4, unit: Unit.pcs),
        FridgeItem(id: 'carrot', name: 'Морковь', amount: 2, unit: Unit.pcs),
        FridgeItem(
          id: 'cucumber',
          name: 'Маринованные огурцы',
          amount: 3,
          unit: Unit.pcs,
        ),
        FridgeItem(
          id: 'peas',
          name: 'Зеленый горошек',
          amount: 180,
          unit: Unit.g,
        ),
      ],
    ),
    BenchmarkScenario(
      id: 'borscht_set',
      label: 'Борщевой набор',
      expectedTitleFragments: const ['борщ'],
      shelfCanonicals: const [
        'соль',
        'перец',
        'лавровый лист',
        'сметана',
        'томатная паста',
        'укроп',
      ],
      fridgeItems: const [
        FridgeItem(id: 'beetroot', name: 'Свекла', amount: 2, unit: Unit.pcs),
        FridgeItem(id: 'cabbage', name: 'Капуста', amount: 700, unit: Unit.g),
        FridgeItem(id: 'potato', name: 'Картофель', amount: 4, unit: Unit.pcs),
        FridgeItem(id: 'carrot', name: 'Морковь', amount: 2, unit: Unit.pcs),
        FridgeItem(id: 'onion', name: 'Лук', amount: 1, unit: Unit.pcs),
        FridgeItem(
          id: 'beef',
          name: 'Говядина',
          amount: 320,
          unit: Unit.g,
        ),
      ],
    ),
    BenchmarkScenario(
      id: 'ukha_set',
      label: 'Уха из рыбы',
      expectedTitleFragments: const ['уха'],
      shelfCanonicals: const ['соль', 'перец', 'лавровый лист', 'укроп', 'лимон'],
      fridgeItems: const [
        FridgeItem(id: 'fish', name: 'Рыба', amount: 420, unit: Unit.g),
        FridgeItem(id: 'potato', name: 'Картофель', amount: 4, unit: Unit.pcs),
        FridgeItem(id: 'carrot', name: 'Морковь', amount: 2, unit: Unit.pcs),
        FridgeItem(id: 'onion', name: 'Лук', amount: 1, unit: Unit.pcs),
      ],
    ),
    BenchmarkScenario(
      id: 'rassolnik_set',
      label: 'Рассольник с перловкой',
      expectedTitleFragments: const ['рассольник'],
      shelfCanonicals: const ['соль', 'перец', 'лавровый лист', 'сметана'],
      fridgeItems: const [
        FridgeItem(
          id: 'pearl_barley',
          name: 'Перловая крупа',
          amount: 220,
          unit: Unit.g,
        ),
        FridgeItem(
          id: 'cucumber',
          name: 'Соленые огурцы',
          amount: 3,
          unit: Unit.pcs,
        ),
        FridgeItem(id: 'potato', name: 'Картофель', amount: 4, unit: Unit.pcs),
        FridgeItem(id: 'carrot', name: 'Морковь', amount: 2, unit: Unit.pcs),
        FridgeItem(id: 'onion', name: 'Лук', amount: 1, unit: Unit.pcs),
      ],
    ),
    BenchmarkScenario(
      id: 'solyanka_set',
      label: 'Солянка с копчёностями',
      expectedTitleFragments: const ['солянка'],
      shelfCanonicals: const [
        'соль',
        'перец',
        'лавровый лист',
        'сметана',
        'лимон',
      ],
      fridgeItems: const [
        FridgeItem(
          id: 'sausage',
          name: 'Копченая колбаса',
          amount: 260,
          unit: Unit.g,
        ),
        FridgeItem(
          id: 'olives',
          name: 'Маслины',
          amount: 120,
          unit: Unit.g,
        ),
        FridgeItem(
          id: 'cucumber',
          name: 'Соленые огурцы',
          amount: 3,
          unit: Unit.pcs,
        ),
        FridgeItem(id: 'onion', name: 'Лук', amount: 1, unit: Unit.pcs),
        FridgeItem(
          id: 'tomato_paste',
          name: 'Томатная паста',
          amount: 120,
          unit: Unit.g,
        ),
        FridgeItem(id: 'lemon', name: 'Лимон', amount: 1, unit: Unit.pcs),
      ],
    ),
    BenchmarkScenario(
      id: 'draniki_set',
      label: 'Драники',
      expectedTitleFragments: const ['драники'],
      shelfCanonicals: const ['соль', 'перец', 'масло', 'сметана'],
      fridgeItems: const [
        FridgeItem(id: 'potato', name: 'Картофель', amount: 6, unit: Unit.pcs),
        FridgeItem(id: 'onion', name: 'Лук', amount: 1, unit: Unit.pcs),
        FridgeItem(id: 'egg', name: 'Яйца', amount: 2, unit: Unit.pcs),
        FridgeItem(id: 'flour', name: 'Мука', amount: 180, unit: Unit.g),
      ],
    ),
    BenchmarkScenario(
      id: 'lazy_golubtsy_set',
      label: 'Ленивые голубцы',
      expectedTitleFragments: const ['ленивые голубцы'],
      shelfCanonicals: const [
        'соль',
        'перец',
        'томатная паста',
        'сметана',
        'лавровый лист',
      ],
      fridgeItems: const [
        FridgeItem(id: 'mince', name: 'Фарш', amount: 420, unit: Unit.g),
        FridgeItem(id: 'rice', name: 'Рис', amount: 260, unit: Unit.g),
        FridgeItem(id: 'cabbage', name: 'Капуста', amount: 900, unit: Unit.g),
        FridgeItem(id: 'onion', name: 'Лук', amount: 1, unit: Unit.pcs),
        FridgeItem(id: 'carrot', name: 'Морковь', amount: 2, unit: Unit.pcs),
      ],
    ),
    BenchmarkScenario(
      id: 'kotlet_dinner_set',
      label: 'Котлеты с гарниром',
      expectedTitleFragments: const ['котлеты'],
      shelfCanonicals: const ['соль', 'перец', 'масло', 'сметана'],
      fridgeItems: const [
        FridgeItem(
          id: 'cutlets',
          name: 'Домашние котлеты',
          amount: 420,
          unit: Unit.g,
        ),
        FridgeItem(id: 'buckwheat', name: 'Гречка', amount: 220, unit: Unit.g),
        FridgeItem(id: 'onion', name: 'Лук', amount: 1, unit: Unit.pcs),
        FridgeItem(id: 'carrot', name: 'Морковь', amount: 2, unit: Unit.pcs),
      ],
    ),
    BenchmarkScenario(
      id: 'stewed_cabbage_set',
      label: 'Тушёная капуста',
      expectedTitleFragments: const ['тушеная капуста', 'тушёная капуста'],
      shelfCanonicals: const ['соль', 'перец', 'лавровый лист', 'томатная паста'],
      fridgeItems: const [
        FridgeItem(id: 'cabbage', name: 'Капуста', amount: 900, unit: Unit.g),
        FridgeItem(id: 'sausage', name: 'Колбаса', amount: 240, unit: Unit.g),
        FridgeItem(id: 'onion', name: 'Лук', amount: 1, unit: Unit.pcs),
        FridgeItem(id: 'carrot', name: 'Морковь', amount: 2, unit: Unit.pcs),
        FridgeItem(
          id: 'tomato_paste',
          name: 'Томатная паста',
          amount: 120,
          unit: Unit.g,
        ),
      ],
    ),
    BenchmarkScenario(
      id: 'millet_kasha_set',
      label: 'Пшённая каша',
      expectedTitleFragments: const ['пшенная каша', 'пшённая каша'],
      shelfCanonicals: const ['сахар', 'корица'],
      fridgeItems: const [
        FridgeItem(
          id: 'millet',
          name: 'Пшенная крупа',
          amount: 220,
          unit: Unit.g,
        ),
        FridgeItem(id: 'milk', name: 'Молоко', amount: 1, unit: Unit.l),
        FridgeItem(
          id: 'butter',
          name: 'Сливочное масло',
          amount: 120,
          unit: Unit.g,
        ),
        FridgeItem(id: 'apple', name: 'Яблоко', amount: 1, unit: Unit.pcs),
      ],
    ),
    BenchmarkScenario(
      id: 'rice_kasha_set',
      label: 'Рисовая каша',
      expectedTitleFragments: const ['рисовая каша'],
      shelfCanonicals: const ['сахар', 'корица'],
      fridgeItems: const [
        FridgeItem(id: 'rice', name: 'Рис', amount: 240, unit: Unit.g),
        FridgeItem(id: 'milk', name: 'Молоко', amount: 1, unit: Unit.l),
        FridgeItem(
          id: 'butter',
          name: 'Сливочное масло',
          amount: 120,
          unit: Unit.g,
        ),
      ],
    ),
    BenchmarkScenario(
      id: 'manna_kasha_set',
      label: 'Манная каша',
      expectedTitleFragments: const ['манная каша'],
      shelfCanonicals: const ['сахар', 'корица'],
      fridgeItems: const [
        FridgeItem(id: 'semolina', name: 'Манка', amount: 180, unit: Unit.g),
        FridgeItem(id: 'milk', name: 'Молоко', amount: 1, unit: Unit.l),
        FridgeItem(
          id: 'butter',
          name: 'Сливочное масло',
          amount: 120,
          unit: Unit.g,
        ),
      ],
    ),
  ];

  var top1Hits = 0;
  var top3Hits = 0;
  var generatedTop1Hits = 0;

  stdout.writeln('Offline Chef Benchmark');
  stdout.writeln('Scenarios: ${scenarios.length}');
  stdout.writeln('');

  for (final scenario in scenarios) {
    final shelfItems = _buildShelfItems(
      pantry: pantry,
      wantedCanonicals: scenario.shelfCanonicals,
    );
    final generated = engine.generate(
      OfflineChefRequest(
        baseRecipes: recipes,
        fridgeItems: scenario.fridgeItems,
        shelfItems: shelfItems,
        productCatalog: products,
        pantryCatalog: pantry,
      ),
    );
    final ranked = rankBestRecipes(
      recipes: recipes,
      generatedRecipes: generated.map((candidate) => candidate.recipe).toList(),
      fridgeItems: scenario.fridgeItems,
      shelfItems: shelfItems,
      catalog: products,
      now: now,
    );
    final top3 = ranked.take(3).toList();
    final top1Hit =
        top3.isNotEmpty && _matchesExpected(top3.first.recipe.title, scenario);
    final top3Hit = top3.any((match) => _matchesExpected(match.recipe.title, scenario));
    final generatedTop1 = top1Hit &&
        top3.first.source == RecipeMatchSource.generated;

    if (top1Hit) {
      top1Hits++;
    }
    if (top3Hit) {
      top3Hits++;
    }
    if (generatedTop1) {
      generatedTop1Hits++;
    }

    stdout.writeln(
      '[${top3Hit ? 'PASS' : 'FAIL'}] ${scenario.label}'
      ' | top1=${top1Hit ? 'yes' : 'no'}'
      ' | top3=${top3Hit ? 'yes' : 'no'}',
    );
    if (top3.isEmpty) {
      stdout.writeln('  no ranked results');
      continue;
    }
    for (var index = 0; index < top3.length; index++) {
      final match = top3[index];
      stdout.writeln(
        '  ${index + 1}. ${match.recipe.title}'
        ' [${match.source.label}]'
        ' score=${match.score.toStringAsFixed(3)}',
      );
    }
    stdout.writeln('');
  }

  stdout.writeln('Summary');
  stdout.writeln('  top1 hits: $top1Hits/${scenarios.length}');
  stdout.writeln('  top3 hits: $top3Hits/${scenarios.length}');
  stdout.writeln('  generated top1 hits: $generatedTop1Hits/${scenarios.length}');

  exitCode = top3Hits == scenarios.length ? 0 : 1;
}

bool _matchesExpected(String title, BenchmarkScenario scenario) {
  final normalizedTitle = title.toLowerCase().replaceAll('ё', 'е');
  for (final fragment in scenario.expectedTitleFragments) {
    final normalizedFragment = fragment.toLowerCase().replaceAll('ё', 'е');
    if (normalizedTitle.contains(normalizedFragment)) {
      return true;
    }
  }
  return false;
}

List<ProductCatalogEntry> _loadProducts() {
  final jsonText = File('assets/products/catalog_ru.json').readAsStringSync();
  final raw = jsonDecode(jsonText) as List<dynamic>;
  return raw
      .map((entry) =>
          ProductCatalogEntry.fromJson(entry as Map<String, dynamic>))
      .toList();
}

List<PantryCatalogEntry> _loadPantry() {
  final jsonText = File('assets/pantry/catalog_ru.json').readAsStringSync();
  final raw = jsonDecode(jsonText) as List<dynamic>;
  return raw
      .map(
          (entry) => PantryCatalogEntry.fromJson(entry as Map<String, dynamic>))
      .toList();
}

List<Recipe> _loadRecipes() {
  final jsonText = File('assets/recipes/recipes.json').readAsStringSync();
  final raw = jsonDecode(jsonText) as List<dynamic>;
  return raw
      .map((entry) => Recipe.fromJson(entry as Map<String, dynamic>))
      .toList();
}

List<ShelfItem> _buildShelfItems({
  required List<PantryCatalogEntry> pantry,
  required List<String> wantedCanonicals,
}) {
  final items = <ShelfItem>[];
  for (final canonical in wantedCanonicals) {
    final entry = pantry.where((item) => item.canonicalName == canonical).firstOrNull;
    if (entry == null) {
      continue;
    }
    items.add(
      ShelfItem(
        id: entry.id,
        name: entry.name,
        inStock: true,
        canonicalName: entry.canonicalName,
        category: entry.category,
        supportCanonicals: entry.supportCanonicals,
        isBlend: entry.isBlend,
      ),
    );
  }
  return items;
}
