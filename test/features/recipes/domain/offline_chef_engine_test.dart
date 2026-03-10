import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/fridge/domain/fridge_item.dart';
import 'package:help_to_cook/features/fridge/domain/product_catalog_entry.dart';
import 'package:help_to_cook/features/recipes/domain/ingredient_knowledge.dart';
import 'package:help_to_cook/features/recipes/domain/offline_chef_engine.dart';
import 'package:help_to_cook/features/recipes/domain/recipe.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_ingredient.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_interaction_event.dart';
import 'package:help_to_cook/features/recipes/domain/taste_profile.dart';
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
            id: 'oil',
            name: 'Масло',
            canonicalName: 'масло',
            aliases: ['масло'],
            category: 'oil',
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
      implicit.every(
        (item) => item == 'Соль' || item == 'Черный перец' || item == 'Масло',
      ),
      isTrue,
    );
    expect(implicit, isNot(contains('Базилик')));
  });

  test('does not fake skillet dish when cooking fat support is absent', () {
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
        ],
      ),
    );

    expect(
      generated.any((candidate) => candidate.recipe.chefProfile == 'skillet'),
      isFalse,
    );
  });

  test('does not generate dish from trace anchor stock', () {
    final generated = const OfflineChefEngine().generate(
      _request(
        fridgeItems: const [
          FridgeItem(id: 'egg', name: 'Яйца', amount: 1, unit: Unit.pcs),
          FridgeItem(id: 'tomato', name: 'Помидоры', amount: 2, unit: Unit.pcs),
          FridgeItem(id: 'cheese', name: 'Сыр', amount: 180, unit: Unit.g),
        ],
      ),
    );

    expect(generated, isEmpty);
  });

  test('adapts generated ingredient amount to available stock', () {
    final generated = const OfflineChefEngine().generate(
      _request(
        fridgeItems: const [
          FridgeItem(id: 'egg', name: 'Яйца', amount: 6, unit: Unit.pcs),
          FridgeItem(id: 'tomato', name: 'Помидоры', amount: 2, unit: Unit.pcs),
          FridgeItem(id: 'cheese', name: 'Сыр', amount: 120, unit: Unit.g),
        ],
      ),
    );

    expect(generated, isNotEmpty);
    final cheeseIngredients = [
      for (final candidate in generated)
        for (final ingredient in candidate.recipe.ingredients)
          if (ingredient.name == 'Сыр') ingredient,
    ];
    expect(cheeseIngredients, isNotEmpty);
    expect(
      cheeseIngredients.every((ingredient) => ingredient.unit == Unit.g),
      isTrue,
    );
    expect(
      cheeseIngredients.every((ingredient) => ingredient.amount <= 120),
      isTrue,
    );
  });

  test('builds borscht from classic russian soup set', () {
    final now = DateTime(2026, 3, 9, 12);
    final generated = const OfflineChefEngine().generate(
      _request(
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
            id: 'beetroot',
            name: 'Свекла',
            canonicalName: 'свекла',
            synonyms: ['свекла', 'свёкла'],
            defaultUnit: Unit.pcs,
          ),
          ProductCatalogEntry(
            id: 'cabbage',
            name: 'Капуста',
            canonicalName: 'капуста',
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
            id: 'tomato_paste',
            name: 'Томатная паста',
            canonicalName: 'томатная паста',
            synonyms: ['томатная паста'],
            defaultUnit: Unit.g,
          ),
        ],
        fridgeItems: [
          FridgeItem(
            id: 'beetroot',
            name: 'Свекла',
            amount: 2,
            unit: Unit.pcs,
            expiresAt: now.add(const Duration(days: 1)),
          ),
          const FridgeItem(
            id: 'cabbage',
            name: 'Капуста',
            amount: 500,
            unit: Unit.g,
          ),
          const FridgeItem(
            id: 'potato',
            name: 'Картофель',
            amount: 4,
            unit: Unit.pcs,
          ),
          const FridgeItem(
            id: 'carrot',
            name: 'Морковь',
            amount: 2,
            unit: Unit.pcs,
          ),
          const FridgeItem(
            id: 'onion',
            name: 'Лук',
            amount: 1,
            unit: Unit.pcs,
          ),
          const FridgeItem(
            id: 'tomato_paste',
            name: 'Томатная паста',
            amount: 120,
            unit: Unit.g,
          ),
        ],
      ),
    );

    final borscht = generated.firstWhere(
      (candidate) => candidate.recipe.title.contains('Борщ'),
    );

    expect(generated, isNotEmpty);
    expect(borscht.recipe.title, contains('Борщ'));
    expect(borscht.recipe.chefProfile, 'soup');
    expect(borscht.recipe.anchorIngredients, contains('Свекла'));
    expect(
      borscht.recipe.steps.any(
        (step) => step.contains('томатная паста'),
      ),
      isTrue,
    );
    expect(
      borscht.recipe.steps.any(
        (step) => step.contains('20-25 минут'),
      ),
      isTrue,
    );
  });

  test('builds shchi from cabbage and root vegetables', () {
    final generated = const OfflineChefEngine().generate(
      _request(
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
            id: 'sour_cream',
            name: 'Сметана',
            canonicalName: 'сметана',
            aliases: ['сметана'],
            category: 'dairy',
            isStarter: true,
          ),
        ],
        fridgeItems: const [
          FridgeItem(id: 'cabbage', name: 'Капуста', amount: 500, unit: Unit.g),
          FridgeItem(
              id: 'potato', name: 'Картофель', amount: 4, unit: Unit.pcs),
          FridgeItem(id: 'carrot', name: 'Морковь', amount: 2, unit: Unit.pcs),
          FridgeItem(id: 'onion', name: 'Лук', amount: 1, unit: Unit.pcs),
          FridgeItem(id: 'chicken', name: 'Курица', amount: 420, unit: Unit.g),
        ],
      ),
    );

    final shchi = generated.firstWhere(
      (candidate) => candidate.recipe.title.contains('Щи'),
    );

    expect(shchi.recipe.chefProfile, 'soup');
    expect(shchi.recipe.anchorIngredients, contains('Капуста'));
    expect(
      shchi.recipe.steps.any((step) => step.contains('18-22 минуты')),
      isTrue,
    );
    expect(
      shchi.recipe.steps.any(
        (step) =>
            step.contains('сметан') ||
            step.contains('укроп') ||
            step.contains('лавров'),
      ),
      isTrue,
    );
  });

  test('ingredient families let chef cook from specific real products', () {
    final generated = const OfflineChefEngine().generate(
      _request(
        productCatalog: const [
          ProductCatalogEntry(
            id: 'glass_noodles',
            name: 'Фунчоза',
            canonicalName: 'макароны',
            synonyms: ['фунчоза', 'фунчеза', 'фанзю'],
            defaultUnit: Unit.g,
          ),
          ProductCatalogEntry(
            id: 'mozzarella',
            name: 'Моцарелла',
            canonicalName: 'сыр',
            synonyms: ['моцарелла'],
            defaultUnit: Unit.g,
          ),
          ProductCatalogEntry(
            id: 'tomato',
            name: 'Помидоры',
            canonicalName: 'помидор',
            synonyms: ['помидор', 'томаты'],
            defaultUnit: Unit.pcs,
          ),
          ProductCatalogEntry(
            id: 'garlic',
            name: 'Чеснок',
            canonicalName: 'чеснок',
            synonyms: ['чеснок'],
            defaultUnit: Unit.pcs,
          ),
        ],
        fridgeItems: const [
          FridgeItem(id: 'glass', name: 'Фанзю', amount: 220, unit: Unit.g),
          FridgeItem(id: 'mozz', name: 'Моцарелла', amount: 125, unit: Unit.g),
          FridgeItem(id: 'tomato', name: 'Помидоры', amount: 3, unit: Unit.pcs),
          FridgeItem(id: 'garlic', name: 'Чеснок', amount: 2, unit: Unit.pcs),
        ],
      ),
    );

    expect(generated, isNotEmpty);
    expect(generated.first.recipe.chefProfile, 'pasta');
    expect(generated.first.recipe.anchorIngredients, contains('Фанзю'));
    expect(
      generated.first.recipe.ingredients.any(
        (ingredient) => ingredient.name == 'Моцарелла',
      ),
      isTrue,
    );
  });

  test('builds olivier from classic russian holiday ingredients', () {
    final generated = const OfflineChefEngine().generate(
      _request(
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
            id: 'mayo',
            name: 'Майонез',
            canonicalName: 'майонез',
            aliases: ['майонез', 'провансаль'],
            category: 'sauce',
            isStarter: true,
          ),
        ],
        productCatalog: const [
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
            synonyms: ['яйцо', 'яйца'],
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
            id: 'cucumber',
            name: 'Огурцы',
            canonicalName: 'огурец',
            synonyms: ['огурец', 'соленые огурцы'],
            defaultUnit: Unit.pcs,
          ),
          ProductCatalogEntry(
            id: 'peas',
            name: 'Горошек',
            canonicalName: 'горошек',
            synonyms: ['горошек', 'зеленый горошек'],
            defaultUnit: Unit.g,
          ),
          ProductCatalogEntry(
            id: 'sausage',
            name: 'Колбаса',
            canonicalName: 'колбаса',
            synonyms: ['колбаса', 'докторская колбаса'],
            defaultUnit: Unit.g,
          ),
        ],
        fridgeItems: const [
          FridgeItem(
            id: 'potato',
            name: 'Картофель',
            amount: 5,
            unit: Unit.pcs,
          ),
          FridgeItem(
            id: 'egg',
            name: 'Яйца',
            amount: 6,
            unit: Unit.pcs,
          ),
          FridgeItem(
            id: 'carrot',
            name: 'Морковь',
            amount: 2,
            unit: Unit.pcs,
          ),
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
    );

    final olivier = generated.firstWhere(
      (candidate) => candidate.recipe.title.contains('Оливье'),
    );

    expect(generated, isNotEmpty);
    expect(olivier.recipe.chefProfile, 'salad');
    expect(
      olivier.recipe.ingredients.any(
        (ingredient) => ingredient.name == 'Майонез',
      ),
      isTrue,
    );
  });

  test('builds syrniki from cottage cheese breakfast set', () {
    final generated = const OfflineChefEngine().generate(
      _request(
        pantryCatalog: const [
          PantryCatalogEntry(
            id: 'sugar',
            name: 'Сахар',
            canonicalName: 'сахар',
            aliases: ['сахар'],
            category: 'basic',
            isStarter: true,
          ),
          PantryCatalogEntry(
            id: 'butter',
            name: 'Сливочное масло',
            canonicalName: 'масло сливочное',
            aliases: ['сливочное масло'],
            category: 'oil',
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
        fridgeItems: const [
          FridgeItem(
            id: 'cottage_cheese',
            name: 'Творог',
            amount: 360,
            unit: Unit.g,
          ),
          FridgeItem(
            id: 'egg',
            name: 'Яйца',
            amount: 2,
            unit: Unit.pcs,
          ),
          FridgeItem(
            id: 'apple',
            name: 'Яблоко',
            amount: 1,
            unit: Unit.pcs,
          ),
        ],
      ),
    );

    final syrniki = generated.firstWhere(
      (candidate) => candidate.recipe.title.contains('Сырники'),
    );

    expect(generated, isNotEmpty);
    expect(syrniki.recipe.chefProfile, 'breakfast');
    expect(
      syrniki.recipe.ingredients.any(
        (ingredient) => ingredient.name == 'Яйца',
      ),
      isTrue,
    );
    expect(
      syrniki.recipe.steps.any(
        (step) => step.contains('2-3 минуты с каждой стороны'),
      ),
      isTrue,
    );
    expect(
      syrniki.recipe.steps.any(
        (step) => step.contains('плотную творожную массу'),
      ),
      isTrue,
    );
    expect(
      syrniki.recipe.steps.any((step) => step.contains('влажными руками')),
      isTrue,
    );
  });

  test('builds blini from flour milk and egg set', () {
    final generated = const OfflineChefEngine().generate(
      _request(
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
            id: 'sugar',
            name: 'Сахар',
            canonicalName: 'сахар',
            aliases: ['сахар'],
            category: 'basic',
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
          PantryCatalogEntry(
            id: 'sour_cream',
            name: 'Сметана',
            canonicalName: 'сметана',
            aliases: ['сметана'],
            category: 'dairy',
            isStarter: true,
          ),
        ],
        fridgeItems: const [
          FridgeItem(id: 'flour', name: 'Мука', amount: 220, unit: Unit.g),
          FridgeItem(id: 'milk', name: 'Молоко', amount: 500, unit: Unit.ml),
          FridgeItem(id: 'egg', name: 'Яйца', amount: 3, unit: Unit.pcs),
        ],
      ),
    );

    final blini = generated.firstWhere(
      (candidate) => candidate.recipe.title.contains('Блины домашние'),
    );

    expect(blini.recipe.chefProfile, 'breakfast');
    expect(
      blini.recipe.steps.any((step) => step.contains('без комков')),
      isTrue,
    );
    expect(
      blini.recipe.steps.any((step) => step.contains('8-10 минут')),
      isTrue,
    );
    expect(
      blini.recipe.steps.any(
        (step) => step.contains('1-2 минуты с каждой стороны'),
      ),
      isTrue,
    );
  });

  test('builds oladyi from kefir flour and egg set', () {
    final generated = const OfflineChefEngine().generate(
      _request(
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
            id: 'sugar',
            name: 'Сахар',
            canonicalName: 'сахар',
            aliases: ['сахар'],
            category: 'basic',
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
          PantryCatalogEntry(
            id: 'sour_cream',
            name: 'Сметана',
            canonicalName: 'сметана',
            aliases: ['сметана'],
            category: 'dairy',
            isStarter: true,
          ),
        ],
        fridgeItems: const [
          FridgeItem(id: 'flour', name: 'Мука', amount: 220, unit: Unit.g),
          FridgeItem(id: 'kefir', name: 'Кефир', amount: 700, unit: Unit.ml),
          FridgeItem(id: 'egg', name: 'Яйца', amount: 2, unit: Unit.pcs),
        ],
      ),
    );

    final oladyi = generated.firstWhere(
      (candidate) => candidate.recipe.title.contains('Оладьи на кефире'),
    );

    expect(oladyi.recipe.chefProfile, 'breakfast');
    expect(
      oladyi.recipe.steps.any((step) => step.contains('густое тесто')),
      isTrue,
    );
    expect(
      oladyi.recipe.steps.any((step) => step.contains('небольшими порциями')),
      isTrue,
    );
    expect(
      oladyi.recipe.steps.any(
        (step) => step.contains('2-3 минуты с каждой стороны'),
      ),
      isTrue,
    );
  });

  test('builds vinegret from classic russian root salad set', () {
    final generated = const OfflineChefEngine().generate(
      _request(
        fridgeItems: const [
          FridgeItem(
            id: 'beetroot',
            name: 'Свекла',
            amount: 2,
            unit: Unit.pcs,
          ),
          FridgeItem(
            id: 'potato',
            name: 'Картофель',
            amount: 4,
            unit: Unit.pcs,
          ),
          FridgeItem(
            id: 'carrot',
            name: 'Морковь',
            amount: 2,
            unit: Unit.pcs,
          ),
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
            id: 'oil',
            name: 'Масло',
            canonicalName: 'масло',
            aliases: ['масло'],
            category: 'oil',
            isStarter: true,
          ),
        ],
      ),
    );

    final vinegret = generated.firstWhere(
      (candidate) => candidate.recipe.title.contains('Винегрет'),
    );

    expect(vinegret.recipe.chefProfile, 'salad');
    expect(
      vinegret.recipe.ingredients
          .any((ingredient) => ingredient.name == 'Масло'),
      isTrue,
    );
  });

  test('builds ukha from fish and root vegetables', () {
    final generated = const OfflineChefEngine().generate(
      _request(
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
            id: 'dill',
            name: 'Укроп',
            canonicalName: 'укроп',
            aliases: ['укроп'],
            category: 'herb',
            isStarter: true,
          ),
          PantryCatalogEntry(
            id: 'lemon',
            name: 'Лимонный сок',
            canonicalName: 'лимон',
            aliases: ['лимонный сок'],
            category: 'sauce',
            isStarter: true,
          ),
        ],
        fridgeItems: const [
          FridgeItem(id: 'fish', name: 'Рыба', amount: 420, unit: Unit.g),
          FridgeItem(
            id: 'potato',
            name: 'Картофель',
            amount: 4,
            unit: Unit.pcs,
          ),
          FridgeItem(id: 'carrot', name: 'Морковь', amount: 2, unit: Unit.pcs),
          FridgeItem(id: 'onion', name: 'Лук', amount: 1, unit: Unit.pcs),
        ],
      ),
    );

    final ukha = generated.firstWhere(
      (candidate) => candidate.recipe.title.contains('Уха'),
    );

    expect(ukha.recipe.chefProfile, 'soup');
    expect(ukha.recipe.anchorIngredients, contains('Рыба'));
    expect(
      ukha.recipe.steps.any((step) => step.contains('12-15 минут')),
      isTrue,
    );
    expect(
      ukha.recipe.steps.any((step) => step.contains('8-10 минут')),
      isTrue,
    );
  });

  test('builds okroshka from kefir cucumber and egg set', () {
    final generated = const OfflineChefEngine().generate(
      _request(
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
        fridgeItems: const [
          FridgeItem(id: 'kefir', name: 'Кефир', amount: 900, unit: Unit.ml),
          FridgeItem(
            id: 'potato',
            name: 'Картофель',
            amount: 5,
            unit: Unit.pcs,
          ),
          FridgeItem(id: 'egg', name: 'Яйца', amount: 4, unit: Unit.pcs),
          FridgeItem(
            id: 'cucumber',
            name: 'Огурцы',
            amount: 3,
            unit: Unit.pcs,
          ),
          FridgeItem(
            id: 'sausage',
            name: 'Колбаса',
            amount: 220,
            unit: Unit.g,
          ),
          FridgeItem(id: 'dill', name: 'Укроп', amount: 30, unit: Unit.g),
        ],
      ),
    );

    final okroshka = generated.firstWhere(
      (candidate) => candidate.recipe.title.contains('Окрошка на кефире'),
    );

    expect(okroshka.recipe.chefProfile, 'soup');
    expect(
      okroshka.recipe.ingredients
          .any((ingredient) => ingredient.name == 'Кефир'),
      isTrue,
    );
    expect(
      okroshka.recipe.steps.any((step) => step.contains('в холоде 5-7 минут')),
      isTrue,
    );
    expect(
      okroshka.recipe.steps.any((step) => step.contains('подавай холодной')),
      isTrue,
    );
  });

  test('builds okroshka from kvass cucumber and egg set', () {
    final generated = const OfflineChefEngine().generate(
      _request(
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
        fridgeItems: const [
          FridgeItem(id: 'kvass', name: 'Квас', amount: 1200, unit: Unit.ml),
          FridgeItem(
            id: 'potato',
            name: 'Картофель',
            amount: 5,
            unit: Unit.pcs,
          ),
          FridgeItem(id: 'egg', name: 'Яйца', amount: 4, unit: Unit.pcs),
          FridgeItem(
            id: 'cucumber',
            name: 'Огурцы',
            amount: 3,
            unit: Unit.pcs,
          ),
          FridgeItem(
            id: 'sausage',
            name: 'Колбаса',
            amount: 220,
            unit: Unit.g,
          ),
          FridgeItem(id: 'dill', name: 'Укроп', amount: 30, unit: Unit.g),
        ],
      ),
    );

    final okroshka = generated.firstWhere(
      (candidate) => candidate.recipe.title.contains('Окрошка на квасе'),
    );

    expect(okroshka.recipe.chefProfile, 'soup');
    expect(
      okroshka.recipe.ingredients
          .any((ingredient) => ingredient.name == 'Квас'),
      isTrue,
    );
    expect(
      okroshka.recipe.steps.any((step) => step.contains('Влей Квас')),
      isTrue,
    );
    expect(
      okroshka.recipe.steps.any((step) => step.contains('подавай холодной')),
      isTrue,
    );
  });

  test('builds rassolnik from pearl barley and pickles', () {
    final generated = const OfflineChefEngine().generate(
      _request(
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
            id: 'sour_cream',
            name: 'Сметана',
            canonicalName: 'сметана',
            aliases: ['сметана'],
            category: 'dairy',
            isStarter: true,
          ),
        ],
        fridgeItems: const [
          FridgeItem(
            id: 'pearl_barley',
            name: 'Перловая крупа',
            amount: 220,
            unit: Unit.g,
          ),
          FridgeItem(
            id: 'cucumber',
            name: 'Маринованные огурцы',
            amount: 3,
            unit: Unit.pcs,
          ),
          FridgeItem(
            id: 'potato',
            name: 'Картофель',
            amount: 4,
            unit: Unit.pcs,
          ),
          FridgeItem(id: 'carrot', name: 'Морковь', amount: 2, unit: Unit.pcs),
          FridgeItem(id: 'onion', name: 'Лук', amount: 1, unit: Unit.pcs),
        ],
      ),
    );

    final rassolnik = generated.firstWhere(
      (candidate) => candidate.recipe.title.contains('Рассольник'),
    );

    expect(rassolnik.recipe.chefProfile, 'soup');
    expect(
      rassolnik.recipe.anchorIngredients.any(
            (ingredient) => ingredient.contains('Перлов'),
          ) ||
          rassolnik.recipe.ingredients.any(
            (ingredient) => ingredient.name.contains('Перлов'),
          ),
      isTrue,
    );
  });

  test('builds draniki from potatoes, onion and egg', () {
    final generated = const OfflineChefEngine().generate(
      _request(
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
          PantryCatalogEntry(
            id: 'sour_cream',
            name: 'Сметана',
            canonicalName: 'сметана',
            aliases: ['сметана'],
            category: 'dairy',
            isStarter: true,
          ),
        ],
        fridgeItems: const [
          FridgeItem(
            id: 'potato',
            name: 'Картофель',
            amount: 6,
            unit: Unit.pcs,
          ),
          FridgeItem(id: 'onion', name: 'Лук', amount: 1, unit: Unit.pcs),
          FridgeItem(id: 'egg', name: 'Яйца', amount: 2, unit: Unit.pcs),
        ],
      ),
    );

    final draniki = generated.firstWhere(
      (candidate) => candidate.recipe.title.contains('Драники'),
    );

    expect(draniki.recipe.chefProfile, 'skillet');
    expect(
      draniki.recipe.ingredients.any((ingredient) => ingredient.name == 'Лук'),
      isTrue,
    );
    expect(
      draniki.recipe.steps.any((step) => step.contains('отожми')),
      isTrue,
    );
    expect(
      draniki.recipe.steps.any((step) => step.contains('без лишней влаги')),
      isTrue,
    );
    expect(
      draniki.recipe.steps.any(
        (step) => step.contains('3-4 минуты с каждой стороны'),
      ),
      isTrue,
    );
  });

  test('builds stewed cabbage from home-style pantry set', () {
    final generated = const OfflineChefEngine().generate(
      _request(
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
        fridgeItems: const [
          FridgeItem(id: 'cabbage', name: 'Капуста', amount: 900, unit: Unit.g),
          FridgeItem(
            id: 'sausage',
            name: 'Колбаса',
            amount: 240,
            unit: Unit.g,
          ),
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
    );

    final stewedCabbage = generated.firstWhere(
      (candidate) => candidate.recipe.title.contains('Тушёная капуста'),
    );

    expect(stewedCabbage.recipe.chefProfile, 'stew');
    expect(
      stewedCabbage.recipe.ingredients.any(
        (ingredient) => ingredient.name == 'Томатная паста',
      ),
      isTrue,
    );
  });

  test('builds solyanka from salty-smoky russian soup set', () {
    final generated = const OfflineChefEngine().generate(
      _request(
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
            id: 'sour_cream',
            name: 'Сметана',
            canonicalName: 'сметана',
            aliases: ['сметана'],
            category: 'dairy',
            isStarter: true,
          ),
          PantryCatalogEntry(
            id: 'lemon',
            name: 'Лимонный сок',
            canonicalName: 'лимон',
            aliases: ['лимонный сок'],
            category: 'sauce',
            isStarter: true,
          ),
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
    );

    final solyanka = generated.firstWhere(
      (candidate) => candidate.recipe.title.contains('Солянка'),
    );

    expect(solyanka.recipe.chefProfile, 'soup');
    expect(
      solyanka.recipe.ingredients.any(
        (ingredient) =>
            ingredient.name.contains('Олив') ||
            ingredient.name.contains('Маслин'),
      ),
      isTrue,
    );
    expect(
      solyanka.recipe.steps.any((step) => step.contains('томатная паста')),
      isTrue,
    );
    expect(
      solyanka.recipe.steps.any(
        (step) => step.contains('в конце добавь') && step.contains('лимон'),
      ),
      isTrue,
    );
  });

  test('builds lazy cabbage rolls from mince cabbage and rice', () {
    final generated = const OfflineChefEngine().generate(
      _request(
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
            id: 'tomato_paste',
            name: 'Томатная паста',
            canonicalName: 'томатная паста',
            aliases: ['томатная паста'],
            category: 'sauce',
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
        fridgeItems: const [
          FridgeItem(id: 'mince', name: 'Фарш', amount: 420, unit: Unit.g),
          FridgeItem(id: 'rice', name: 'Рис', amount: 260, unit: Unit.g),
          FridgeItem(id: 'cabbage', name: 'Капуста', amount: 900, unit: Unit.g),
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
    );

    final golubtsy = generated.firstWhere(
      (candidate) => candidate.recipe.title.contains('Ленивые голубцы'),
    );

    expect(golubtsy.recipe.chefProfile, 'stew');
    expect(
      golubtsy.recipe.ingredients.any(
        (ingredient) => ingredient.name == 'Капуста',
      ),
      isTrue,
    );
    expect(
      golubtsy.recipe.steps.any(
        (step) =>
            step.contains('туши ленивые голубцы') &&
            step.contains('18-22 минуты'),
      ),
      isTrue,
    );
    expect(
      golubtsy.recipe.steps.any(
        (step) =>
            step.contains('плотную основу для ленивых голубцов') ||
            step.contains('томат'),
      ),
      isTrue,
    );
  });

  test('builds home cutlet dinner from mince and garnish set', () {
    final generated = const OfflineChefEngine().generate(
      _request(
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
          PantryCatalogEntry(
            id: 'sour_cream',
            name: 'Сметана',
            canonicalName: 'сметана',
            aliases: ['сметана'],
            category: 'dairy',
            isStarter: true,
          ),
        ],
        fridgeItems: const [
          FridgeItem(
            id: 'cutlets',
            name: 'Домашние котлеты',
            amount: 420,
            unit: Unit.g,
          ),
          FridgeItem(
              id: 'buckwheat', name: 'Гречка', amount: 220, unit: Unit.g),
          FridgeItem(id: 'onion', name: 'Лук', amount: 1, unit: Unit.pcs),
          FridgeItem(id: 'carrot', name: 'Морковь', amount: 2, unit: Unit.pcs),
        ],
      ),
    );

    final kotlety = generated.firstWhere(
      (candidate) => candidate.recipe.title.contains('Котлеты'),
    );

    expect(kotlety.recipe.chefProfile, 'stew');
    expect(
      kotlety.recipe.anchorIngredients.any(
        (ingredient) =>
            ingredient.toLowerCase().contains('котлет') || ingredient == 'Фарш',
      ),
      isTrue,
    );
    expect(
      kotlety.recipe.steps.any(
        (step) =>
            step.contains('сформируй котлеты') &&
            step.contains('4-5 минут с каждой стороны'),
      ),
      isTrue,
    );
    expect(
      kotlety.recipe.steps.any(
        (step) =>
            step.contains('гарнир') &&
            (step.contains('6-8 минут') || step.contains('вместе с гарниром')),
      ),
      isTrue,
    );
  });

  test('builds zharkoe with browning and covered braise', () {
    final generated = const OfflineChefEngine().generate(
      _request(
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
        fridgeItems: const [
          FridgeItem(
            id: 'beef',
            name: 'Говядина',
            amount: 480,
            unit: Unit.g,
          ),
          FridgeItem(
            id: 'potato',
            name: 'Картофель',
            amount: 800,
            unit: Unit.g,
          ),
          FridgeItem(id: 'onion', name: 'Лук', amount: 1, unit: Unit.pcs),
          FridgeItem(id: 'carrot', name: 'Морковь', amount: 2, unit: Unit.pcs),
        ],
      ),
    );

    final zharkoe = generated.firstWhere(
      (candidate) => candidate.recipe.title.contains('Жаркое'),
    );

    expect(zharkoe.recipe.chefProfile, 'stew');
    expect(
      zharkoe.recipe.ingredients.any(
        (ingredient) => ingredient.name == 'Картофель',
      ),
      isTrue,
    );
    expect(
      zharkoe.recipe.steps.any(
        (step) => step.contains('обжарь') && step.contains('5-6 минут'),
      ),
      isTrue,
    );
    expect(
      zharkoe.recipe.steps.any(
        (step) =>
            step.contains('туши жаркое') &&
            step.contains('22-26 минут') &&
            step.contains('под крышкой'),
      ),
      isTrue,
    );
  });

  test('builds zrazy with sealed filling and garnish', () {
    final generated = const OfflineChefEngine().generate(
      _request(
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
        fridgeItems: const [
          FridgeItem(id: 'mince', name: 'Фарш', amount: 420, unit: Unit.g),
          FridgeItem(
            id: 'buckwheat',
            name: 'Гречка',
            amount: 220,
            unit: Unit.g,
          ),
          FridgeItem(id: 'eggs', name: 'Яйца', amount: 3, unit: Unit.pcs),
          FridgeItem(id: 'onion', name: 'Лук', amount: 1, unit: Unit.pcs),
        ],
      ),
    );

    final zrazy = generated.firstWhere(
      (candidate) => candidate.recipe.title.contains('Зразы'),
    );

    expect(zrazy.recipe.chefProfile, 'stew');
    expect(
      zrazy.recipe.ingredients.any(
        (ingredient) => ingredient.name.contains('Яй'),
      ),
      isTrue,
    );
    expect(
      zrazy.recipe.steps.any(
        (step) =>
            step.contains('в центр') &&
            step.contains('закрой края') &&
            step.contains('сформируй зразы'),
      ),
      isTrue,
    );
    expect(
      zrazy.recipe.steps.any(
        (step) =>
            step.contains('Обжарь зразы') &&
            step.contains('4-5 минут с каждой стороны') &&
            step.contains('6-8 минут'),
      ),
      isTrue,
    );
    expect(
      zrazy.recipe.chefNotes.any(
        (note) => note.contains('начинкой внутри'),
      ),
      isTrue,
    );
  });

  test('builds bitochki with gravy finish and garnish', () {
    final generated = const OfflineChefEngine().generate(
      _request(
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
        fridgeItems: const [
          FridgeItem(id: 'mince', name: 'Фарш', amount: 420, unit: Unit.g),
          FridgeItem(
            id: 'potato',
            name: 'Картофель',
            amount: 700,
            unit: Unit.g,
          ),
          FridgeItem(id: 'onion', name: 'Лук', amount: 1, unit: Unit.pcs),
          FridgeItem(id: 'carrot', name: 'Морковь', amount: 1, unit: Unit.pcs),
        ],
      ),
    );

    final bitochki = generated.firstWhere(
      (candidate) => candidate.recipe.title.contains('Биточки'),
    );

    expect(bitochki.recipe.chefProfile, 'stew');
    expect(
      bitochki.recipe.steps.any(
        (step) =>
            step.contains('сформируй круглые биточки') &&
            step.contains('3-4 минуты с каждой стороны'),
      ),
      isTrue,
    );
    expect(
      bitochki.recipe.steps.any(
        (step) =>
            step.contains('подливк') &&
            step.contains('8-10 минут') &&
            step.contains('обволоч'),
      ),
      isTrue,
    );
    expect(
      bitochki.recipe.chefNotes.any(
        (note) => note.contains('мягкой подливке'),
      ),
      isTrue,
    );
  });

  test('builds tefteli with forming and sauce braise', () {
    final generated = const OfflineChefEngine().generate(
      _request(
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
            id: 'tomato_paste',
            name: 'Томатная паста',
            canonicalName: 'томатная паста',
            aliases: ['томатная паста'],
            category: 'sauce',
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
        fridgeItems: const [
          FridgeItem(id: 'mince', name: 'Фарш', amount: 420, unit: Unit.g),
          FridgeItem(id: 'rice', name: 'Рис', amount: 220, unit: Unit.g),
          FridgeItem(id: 'onion', name: 'Лук', amount: 1, unit: Unit.pcs),
          FridgeItem(id: 'carrot', name: 'Морковь', amount: 1, unit: Unit.pcs),
        ],
      ),
    );

    final tefteli = generated.firstWhere(
      (candidate) => candidate.recipe.title.contains('Тефтели'),
    );

    expect(tefteli.recipe.chefProfile, 'stew');
    expect(
      tefteli.recipe.ingredients.any((ingredient) => ingredient.name == 'Рис'),
      isTrue,
    );
    expect(
      tefteli.recipe.steps.any(
        (step) =>
            step.contains('сформируй небольшие тефтели') &&
            step.contains('влажными руками'),
      ),
      isTrue,
    );
    expect(
      tefteli.recipe.steps.any(
        (step) =>
            step.contains('туши их под крышкой 18-22 минуты') &&
            step.contains('соус'),
      ),
      isTrue,
    );
    expect(
      tefteli.recipe.steps.any(
        (step) =>
            step.contains('обволакива') ||
            step.contains('соус успеет собраться'),
      ),
      isTrue,
    );
    expect(
      tefteli.recipe.chefNotes.any(
        (note) => note.contains('томатно-сметанный соус'),
      ),
      isTrue,
    );
  });

  test('builds goulash with paprika depth and long covered simmer', () {
    final generated = const OfflineChefEngine().generate(
      _request(
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
            id: 'paprika',
            name: 'Паприка',
            canonicalName: 'паприка',
            aliases: ['паприка'],
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
        fridgeItems: const [
          FridgeItem(id: 'beef', name: 'Говядина', amount: 500, unit: Unit.g),
          FridgeItem(id: 'onion', name: 'Лук', amount: 2, unit: Unit.pcs),
          FridgeItem(id: 'carrot', name: 'Морковь', amount: 1, unit: Unit.pcs),
        ],
      ),
    );

    final goulash = generated.firstWhere(
      (candidate) => candidate.recipe.title.contains('Гуляш'),
    );

    expect(goulash.recipe.chefProfile, 'stew');
    expect(
      goulash.recipe.steps.any(
        (step) =>
            step.contains('обжарь мясо ещё 5-6 минут') &&
            step.contains('4-5 минут'),
      ),
      isTrue,
    );
    expect(
      goulash.recipe.steps.any(
        (step) =>
            step.contains('туши гуляш под крышкой 25-30 минут') &&
            (step.contains('паприк') || step.contains('томат')),
      ),
      isTrue,
    );
    expect(
      goulash.recipe.steps.any(
        (step) => step.contains('гуще и глубже') && step.contains('выпар'),
      ),
      isTrue,
    );
    expect(
      goulash.recipe.chefNotes.any(
        (note) => note.contains('папрично-томатному соусу'),
      ),
      isTrue,
    );
  });

  test('builds beef stroganoff with strips and gentle sour-cream finish', () {
    final generated = const OfflineChefEngine().generate(
      _request(
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
          PantryCatalogEntry(
            id: 'mustard',
            name: 'Горчица',
            canonicalName: 'горчица',
            aliases: ['горчица'],
            category: 'sauce',
            isStarter: true,
          ),
        ],
        fridgeItems: const [
          FridgeItem(id: 'beef', name: 'Говядина', amount: 480, unit: Unit.g),
          FridgeItem(id: 'onion', name: 'Лук', amount: 1, unit: Unit.pcs),
          FridgeItem(id: 'mushroom', name: 'Грибы', amount: 220, unit: Unit.g),
        ],
      ),
    );

    final stroganoff = generated.firstWhere(
      (candidate) => candidate.recipe.title.contains('Бефстроганов'),
    );

    expect(stroganoff.recipe.chefProfile, 'stew');
    expect(
      stroganoff.recipe.steps.any(
        (step) =>
            step.contains('тонкими полосками') &&
            step.contains('мягкой соусной базы'),
      ),
      isTrue,
    );
    expect(
      stroganoff.recipe.steps.any(
        (step) =>
            step.contains('Быстро обжарь мясо 3-4 минуты') &&
            step.contains('5-7 минут') &&
            step.contains('не давая соусу бурно кипеть'),
      ),
      isTrue,
    );
    expect(
      stroganoff.recipe.steps.any((step) => step.contains('гладк')),
      isTrue,
    );
    expect(
      stroganoff.recipe.chefNotes.any(
        (note) => note.contains('гладком сметанном соусе'),
      ),
      isTrue,
    );
  });

  test('builds makarony po-flotski from pasta and mince set', () {
    final generated = const OfflineChefEngine().generate(
      _request(
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
        fridgeItems: const [
          FridgeItem(id: 'pasta', name: 'Макароны', amount: 320, unit: Unit.g),
          FridgeItem(id: 'mince', name: 'Фарш', amount: 420, unit: Unit.g),
          FridgeItem(id: 'onion', name: 'Лук', amount: 2, unit: Unit.pcs),
          FridgeItem(id: 'carrot', name: 'Морковь', amount: 1, unit: Unit.pcs),
        ],
      ),
    );

    final navyPasta = generated.firstWhere(
      (candidate) => candidate.recipe.title.contains('Макароны по-флотски'),
    );

    expect(navyPasta.recipe.chefProfile, 'pasta');
    expect(
      navyPasta.recipe.ingredients.any(
        (ingredient) => ingredient.name == 'Макароны',
      ),
      isTrue,
    );
    expect(
      navyPasta.recipe.ingredients.any(
        (ingredient) => ingredient.name == 'Фарш',
      ),
      isTrue,
    );
    expect(
      navyPasta.recipe.steps.any((step) => step.contains('8-10 минут')),
      isTrue,
    );
    expect(
      navyPasta.recipe.steps.any((step) => step.contains('2-3 минуты')),
      isTrue,
    );
  });

  test('builds millet kasha from milk breakfast set', () {
    final generated = const OfflineChefEngine().generate(
      _request(
        pantryCatalog: const [
          PantryCatalogEntry(
            id: 'sugar',
            name: 'Сахар',
            canonicalName: 'сахар',
            aliases: ['сахар'],
            category: 'basic',
            isStarter: true,
          ),
          PantryCatalogEntry(
            id: 'cinnamon',
            name: 'Корица',
            canonicalName: 'корица',
            aliases: ['корица'],
            category: 'spice',
            isStarter: true,
          ),
        ],
        fridgeItems: const [
          FridgeItem(
              id: 'millet', name: 'Пшенная крупа', amount: 220, unit: Unit.g),
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
    );

    final kasha = generated.firstWhere(
      (candidate) => candidate.recipe.title.contains('Пшённая каша'),
    );

    expect(kasha.recipe.chefProfile, 'breakfast');
    expect(
      kasha.recipe.ingredients.any((ingredient) => ingredient.name == 'Молоко'),
      isTrue,
    );
  });

  test('builds rice kasha from classic dairy pantry set', () {
    final generated = const OfflineChefEngine().generate(
      _request(
        pantryCatalog: const [
          PantryCatalogEntry(
            id: 'sugar',
            name: 'Сахар',
            canonicalName: 'сахар',
            aliases: ['сахар'],
            category: 'basic',
            isStarter: true,
          ),
          PantryCatalogEntry(
            id: 'cinnamon',
            name: 'Корица',
            canonicalName: 'корица',
            aliases: ['корица'],
            category: 'spice',
            isStarter: true,
          ),
        ],
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
    );

    final kasha = generated.firstWhere(
      (candidate) => candidate.recipe.title.contains('Рисовая каша'),
    );

    expect(kasha.recipe.chefProfile, 'breakfast');
    expect(
      kasha.recipe.ingredients.any(
        (ingredient) => ingredient.name == 'Сливочное масло',
      ),
      isTrue,
    );
  });

  test('builds manna kasha from semolina set', () {
    final generated = const OfflineChefEngine().generate(
      _request(
        pantryCatalog: const [
          PantryCatalogEntry(
            id: 'sugar',
            name: 'Сахар',
            canonicalName: 'сахар',
            aliases: ['сахар'],
            category: 'basic',
            isStarter: true,
          ),
          PantryCatalogEntry(
            id: 'cinnamon',
            name: 'Корица',
            canonicalName: 'корица',
            aliases: ['корица'],
            category: 'spice',
            isStarter: true,
          ),
        ],
        fridgeItems: const [
          FridgeItem(
            id: 'semolina',
            name: 'Манка',
            amount: 180,
            unit: Unit.g,
          ),
          FridgeItem(id: 'milk', name: 'Молоко', amount: 1, unit: Unit.l),
          FridgeItem(
            id: 'butter',
            name: 'Сливочное масло',
            amount: 120,
            unit: Unit.g,
          ),
        ],
      ),
    );

    final kasha = generated.firstWhere(
      (candidate) => candidate.recipe.title.contains('Манная каша'),
    );

    expect(kasha.recipe.chefProfile, 'breakfast');
    expect(
      kasha.recipe.anchorIngredients.any(
        (ingredient) => ingredient.contains('Ман'),
      ),
      isTrue,
    );
  });

  test('builds tvorozhnaya zapekanka from cottage cheese bake set', () {
    final generated = const OfflineChefEngine().generate(
      _request(
        pantryCatalog: const [
          PantryCatalogEntry(
            id: 'sugar',
            name: 'Сахар',
            canonicalName: 'сахар',
            aliases: ['сахар'],
            category: 'basic',
            isStarter: true,
          ),
          PantryCatalogEntry(
            id: 'cinnamon',
            name: 'Корица',
            canonicalName: 'корица',
            aliases: ['корица'],
            category: 'spice',
            isStarter: true,
          ),
        ],
        fridgeItems: const [
          FridgeItem(id: 'curd', name: 'Творог', amount: 500, unit: Unit.g),
          FridgeItem(id: 'egg', name: 'Яйца', amount: 3, unit: Unit.pcs),
          FridgeItem(
            id: 'semolina',
            name: 'Манная крупа',
            amount: 180,
            unit: Unit.g,
          ),
          FridgeItem(id: 'milk', name: 'Молоко', amount: 1, unit: Unit.l),
          FridgeItem(
            id: 'sour_cream',
            name: 'Сметана',
            amount: 180,
            unit: Unit.g,
          ),
        ],
      ),
    );

    final zapekanka = generated.firstWhere(
      (candidate) => candidate.recipe.title.contains('Творожная запеканка'),
    );

    expect(zapekanka.recipe.chefProfile, 'bake');
    expect(
      zapekanka.recipe.anchorIngredients.contains('Творог'),
      isTrue,
    );
    expect(
      zapekanka.recipe.ingredients.any(
        (ingredient) => ingredient.name == 'Манная крупа',
      ),
      isTrue,
    );
  });

  test('builds cabbage egg pie with rested dough and closed filling technique',
      () {
    final generated = const OfflineChefEngine().generate(
      _request(
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
            aliases: ['черный перец', 'перец'],
            category: 'spice',
            isStarter: true,
          ),
          PantryCatalogEntry(
            id: 'butter',
            name: 'Сливочное масло',
            canonicalName: 'масло сливочное',
            aliases: ['сливочное масло', 'масло сливочное'],
            category: 'oil',
            isStarter: true,
          ),
        ],
        fridgeItems: const [
          FridgeItem(id: 'flour', name: 'Мука', amount: 420, unit: Unit.g),
          FridgeItem(
            id: 'cabbage',
            name: 'Капуста',
            amount: 900,
            unit: Unit.g,
          ),
          FridgeItem(id: 'egg', name: 'Яйца', amount: 4, unit: Unit.pcs),
          FridgeItem(id: 'onion', name: 'Лук', amount: 1, unit: Unit.pcs),
          FridgeItem(
            id: 'sour_cream',
            name: 'Сметана',
            amount: 160,
            unit: Unit.g,
          ),
        ],
      ),
    );

    final pie = generated.firstWhere(
      (candidate) => candidate.recipe.title.contains('Пирог домашний'),
    );

    expect(pie.recipe.chefProfile, 'bake');
    expect(
      pie.recipe.anchorIngredients
          .any((ingredient) => ingredient.contains('Кап')),
      isTrue,
    );
    expect(
      pie.recipe.ingredients.any((ingredient) => ingredient.name == 'Мука'),
      isTrue,
    );
    expect(
      pie.recipe.ingredients.any(
        (ingredient) => ingredient.name == 'Сливочное масло',
      ),
      isTrue,
    );
    expect(
      pie.recipe.steps.any((step) => step.contains('Подготовь тесто')),
      isTrue,
    );
    expect(
      pie.recipe.steps.any((step) => step.contains('отдохнуть 20 минут')),
      isTrue,
    );
    expect(
      pie.recipe.steps.any(
        (step) => step.contains('полностью остывшую начинку'),
      ),
      isTrue,
    );
    expect(
      pie.recipe.steps.any((step) => step.contains('защипни края')),
      isTrue,
    );
    expect(
      pie.recipe.steps.any((step) => step.contains('35-40 минут')),
      isTrue,
    );
  });

  test('uses available finishing support from shelf for salad ideas', () {
    final generated = const OfflineChefEngine().generate(
      _request(
        shelfItems: const [
          ShelfItem(
            id: 'oil',
            name: 'Оливковое масло',
            inStock: true,
            canonicalName: 'оливковое масло',
          ),
        ],
        fridgeItems: const [
          FridgeItem(id: 'cucumber', name: 'Огурцы', amount: 2, unit: Unit.pcs),
          FridgeItem(id: 'tomato', name: 'Помидоры', amount: 2, unit: Unit.pcs),
          FridgeItem(id: 'cheese', name: 'Сыр', amount: 180, unit: Unit.g),
        ],
      ),
    );

    final salad = generated.firstWhere(
      (candidate) => candidate.recipe.chefProfile == 'salad',
    );
    expect(
      salad.recipe.ingredients.any(
        (ingredient) => ingredient.name == 'Оливковое масло',
      ),
      isTrue,
    );
    expect(
      salad.reasons.any((reason) => reason.contains('вкус собирают')),
      isTrue,
    );
  });

  test('taste profile steers generation toward liked format', () {
    final generated = const OfflineChefEngine().generate(
      _request(
        tasteProfile: const TasteProfile(
          ingredientWeights: {
            'яйцо': 1.0,
            'сыр': 0.5,
            'макароны': -0.9,
            'курица': -0.5,
          },
          tagWeights: {
            'breakfast': 0.9,
            'one_pan': 0.4,
          },
        ),
        fridgeItems: const [
          FridgeItem(id: 'egg', name: 'Яйца', amount: 6, unit: Unit.pcs),
          FridgeItem(id: 'tomato', name: 'Помидоры', amount: 4, unit: Unit.pcs),
          FridgeItem(id: 'cheese', name: 'Сыр', amount: 220, unit: Unit.g),
          FridgeItem(id: 'pasta', name: 'Макароны', amount: 320, unit: Unit.g),
          FridgeItem(id: 'mushrooms', name: 'Грибы', amount: 180, unit: Unit.g),
          FridgeItem(id: 'chicken', name: 'Курица', amount: 420, unit: Unit.g),
          FridgeItem(id: 'onion', name: 'Лук', amount: 2, unit: Unit.pcs),
        ],
      ),
    );

    expect(generated, isNotEmpty);
    expect(generated.first.recipe.chefProfile, 'skillet');
    expect(generated.first.recipe.anchorIngredients, contains('Яйца'));
  });

  test('recent repetition lowers skillet candidate priority', () {
    final now = DateTime(2026, 3, 9, 12);
    final memoryRecipe = Recipe(
      id: 'memory_omelet',
      title: 'Омлет с сыром',
      timeMin: 10,
      tags: const ['breakfast', 'one_pan'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Яйца', amount: 2, unit: Unit.pcs),
        RecipeIngredient(name: 'Сыр', amount: 40, unit: Unit.g),
        RecipeIngredient(name: 'Помидоры', amount: 120, unit: Unit.g),
      ],
      steps: const ['Взбей', 'Пожарь', 'Подавай'],
    );
    final catalog = _request(
      fridgeItems: const [
        FridgeItem(id: 'egg_seed', name: 'Яйца', amount: 1, unit: Unit.pcs),
      ],
    ).productCatalog;

    final singleRecookProfile = buildTasteProfile(
      feedbackByRecipeId: const {},
      recipes: const [],
      catalog: catalog,
      interactionHistory: [
        RecipeInteractionEvent(
          type: RecipeInteractionType.recooked,
          recipeSnapshot: memoryRecipe,
          occurredAt: now.subtract(const Duration(days: 2)),
        ),
      ],
      referenceTime: now,
    );
    final repeatedRecookProfile = buildTasteProfile(
      feedbackByRecipeId: const {},
      recipes: const [],
      catalog: catalog,
      interactionHistory: [
        RecipeInteractionEvent(
          type: RecipeInteractionType.recooked,
          recipeSnapshot: memoryRecipe,
          occurredAt: now.subtract(const Duration(days: 4)),
        ),
        RecipeInteractionEvent(
          type: RecipeInteractionType.recooked,
          recipeSnapshot: memoryRecipe,
          occurredAt: now.subtract(const Duration(days: 2)),
        ),
        RecipeInteractionEvent(
          type: RecipeInteractionType.recooked,
          recipeSnapshot: memoryRecipe,
          occurredAt: now.subtract(const Duration(days: 1)),
        ),
      ],
      referenceTime: now,
    );

    final singleGenerated = const OfflineChefEngine().generate(
      _request(
        tasteProfile: singleRecookProfile,
        fridgeItems: const [
          FridgeItem(id: 'egg', name: 'Яйца', amount: 6, unit: Unit.pcs),
          FridgeItem(id: 'tomato', name: 'Помидоры', amount: 4, unit: Unit.pcs),
          FridgeItem(id: 'cheese', name: 'Сыр', amount: 220, unit: Unit.g),
          FridgeItem(id: 'pasta', name: 'Макароны', amount: 320, unit: Unit.g),
          FridgeItem(id: 'mushrooms', name: 'Грибы', amount: 180, unit: Unit.g),
          FridgeItem(id: 'chicken', name: 'Курица', amount: 420, unit: Unit.g),
          FridgeItem(id: 'onion', name: 'Лук', amount: 2, unit: Unit.pcs),
        ],
      ),
    );
    final repeatedGenerated = const OfflineChefEngine().generate(
      _request(
        tasteProfile: repeatedRecookProfile,
        fridgeItems: const [
          FridgeItem(id: 'egg', name: 'Яйца', amount: 6, unit: Unit.pcs),
          FridgeItem(id: 'tomato', name: 'Помидоры', amount: 4, unit: Unit.pcs),
          FridgeItem(id: 'cheese', name: 'Сыр', amount: 220, unit: Unit.g),
          FridgeItem(id: 'pasta', name: 'Макароны', amount: 320, unit: Unit.g),
          FridgeItem(id: 'mushrooms', name: 'Грибы', amount: 180, unit: Unit.g),
          FridgeItem(id: 'chicken', name: 'Курица', amount: 420, unit: Unit.g),
          FridgeItem(id: 'onion', name: 'Лук', amount: 2, unit: Unit.pcs),
        ],
      ),
    );

    final singleSkillet = singleGenerated.firstWhere(
      (candidate) => candidate.recipe.chefProfile == 'skillet',
    );
    final repeatedSkillet = repeatedGenerated.firstWhere(
      (candidate) => candidate.recipe.chefProfile == 'skillet',
    );

    expect(singleGenerated, isNotEmpty);
    expect(repeatedGenerated, isNotEmpty);
    expect(
      repeatedSkillet.priorityScore,
      lessThan(singleSkillet.priorityScore),
    );
  });

  test('seed changes generated set without duplicates', () {
    final seedZero = const OfflineChefEngine().generate(
      _request(
        seed: 0,
        fridgeItems: const [
          FridgeItem(id: 'egg', name: 'Яйца', amount: 6, unit: Unit.pcs),
          FridgeItem(id: 'tomato', name: 'Помидоры', amount: 4, unit: Unit.pcs),
          FridgeItem(id: 'cheese', name: 'Сыр', amount: 220, unit: Unit.g),
          FridgeItem(
              id: 'potato', name: 'Картофель', amount: 5, unit: Unit.pcs),
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
          FridgeItem(
              id: 'potato', name: 'Картофель', amount: 5, unit: Unit.pcs),
          FridgeItem(id: 'chicken', name: 'Курица', amount: 450, unit: Unit.g),
          FridgeItem(id: 'rice', name: 'Рис', amount: 250, unit: Unit.g),
          FridgeItem(id: 'pasta', name: 'Макароны', amount: 300, unit: Unit.g),
          FridgeItem(id: 'mushrooms', name: 'Грибы', amount: 180, unit: Unit.g),
          FridgeItem(id: 'onion', name: 'Лук', amount: 2, unit: Unit.pcs),
          FridgeItem(id: 'carrot', name: 'Морковь', amount: 2, unit: Unit.pcs),
        ],
      ),
    );

    expect(
        seedZero.map((item) => item.recipe.id).toSet().length, seedZero.length);
    expect(
        seedOne.map((item) => item.recipe.id).toSet().length, seedOne.length);
    expect(
      seedZero.map((item) => item.recipe.id).toList(),
      isNot(seedOne.map((item) => item.recipe.id).toList()),
    );
  });

  test('does not regenerate broad skillet duplicate against known recipes', () {
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

    expect(generated, isNotEmpty);
    expect(
      generated.any((candidate) {
        if (candidate.recipe.chefProfile != 'skillet') {
          return false;
        }
        final requiredNames = candidate.recipe.ingredients
            .where((ingredient) => ingredient.required)
            .map((ingredient) => ingredient.name)
            .toSet();
        return requiredNames.contains('Яйца') &&
            requiredNames.contains('Помидоры') &&
            requiredNames.contains('Сыр');
      }),
      isFalse,
    );
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
          FridgeItem(
              id: 'potato', name: 'Картофель', amount: 5, unit: Unit.pcs),
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

  test('does not build olivier without potato anchor', () {
    final generated = const OfflineChefEngine().generate(
      _request(
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
            id: 'mayo',
            name: 'Майонез',
            canonicalName: 'майонез',
            aliases: ['майонез'],
            category: 'sauce',
            isStarter: true,
          ),
        ],
        fridgeItems: const [
          FridgeItem(id: 'egg', name: 'Яйца', amount: 6, unit: Unit.pcs),
          FridgeItem(id: 'carrot', name: 'Морковь', amount: 2, unit: Unit.pcs),
          FridgeItem(id: 'cucumber', name: 'Огурцы', amount: 3, unit: Unit.pcs),
          FridgeItem(id: 'peas', name: 'Горошек', amount: 220, unit: Unit.g),
          FridgeItem(id: 'sausage', name: 'Колбаса', amount: 250, unit: Unit.g),
        ],
      ),
    );

    expect(
      generated.any((candidate) => candidate.recipe.title.contains('Оливье')),
      isFalse,
    );
  });

  test('does not build vinegret without beetroot anchor', () {
    final generated = const OfflineChefEngine().generate(
      _request(
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
            id: 'oil',
            name: 'Масло',
            canonicalName: 'масло',
            aliases: ['масло'],
            category: 'basic',
            isStarter: true,
          ),
        ],
        fridgeItems: const [
          FridgeItem(
              id: 'potato', name: 'Картофель', amount: 4, unit: Unit.pcs),
          FridgeItem(id: 'carrot', name: 'Морковь', amount: 2, unit: Unit.pcs),
          FridgeItem(id: 'cucumber', name: 'Огурцы', amount: 3, unit: Unit.pcs),
          FridgeItem(id: 'cabbage', name: 'Капуста', amount: 400, unit: Unit.g),
          FridgeItem(id: 'peas', name: 'Горошек', amount: 200, unit: Unit.g),
        ],
      ),
    );

    expect(
      generated.any((candidate) => candidate.recipe.title.contains('Винегрет')),
      isFalse,
    );
  });

  test('does not build navy pasta without onion base', () {
    final generated = const OfflineChefEngine().generate(
      _request(
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
            category: 'basic',
            isStarter: true,
          ),
        ],
        fridgeItems: const [
          FridgeItem(id: 'pasta', name: 'Макароны', amount: 320, unit: Unit.g),
          FridgeItem(id: 'mince', name: 'Фарш', amount: 420, unit: Unit.g),
          FridgeItem(id: 'carrot', name: 'Морковь', amount: 2, unit: Unit.pcs),
          FridgeItem(
            id: 'tomato_paste',
            name: 'Томатная паста',
            amount: 120,
            unit: Unit.g,
          ),
        ],
      ),
    );

    expect(
      generated.any(
        (candidate) => candidate.recipe.title.contains('Макароны по-флотски'),
      ),
      isFalse,
    );
  });

  test('does not build okroshka without cucumber freshness', () {
    final generated = const OfflineChefEngine().generate(
      _request(
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
        ],
        fridgeItems: const [
          FridgeItem(id: 'kefir', name: 'Кефир', amount: 900, unit: Unit.ml),
          FridgeItem(
            id: 'potato',
            name: 'Картофель',
            amount: 5,
            unit: Unit.pcs,
          ),
          FridgeItem(id: 'egg', name: 'Яйца', amount: 4, unit: Unit.pcs),
          FridgeItem(
            id: 'sausage',
            name: 'Колбаса',
            amount: 220,
            unit: Unit.g,
          ),
          FridgeItem(id: 'dill', name: 'Укроп', amount: 30, unit: Unit.g),
        ],
      ),
    );

    expect(
      generated.any(
        (candidate) => candidate.recipe.title.contains('Окрошка на кефире'),
      ),
      isFalse,
    );
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
      generated.first.reasons
          .any((reason) => reason.contains('шеф берёт в основу')),
      isTrue,
    );
    expect(
      generated.first.reasons
          .any((reason) => reason.contains('лучше пустить в дело сейчас')),
      isTrue,
    );
    expect(
      generated.first.reasons
          .any((reason) => reason.contains('из базовых вещей пригодятся')),
      isTrue,
    );
  });

  // ─── MINIMALIST BLUEPRINT TESTS ────────────────────────────────────────────

  test('builds omelette-family recipe from only eggs and butter pantry', () {
    final generated = const OfflineChefEngine().generate(
      _request(
        fridgeItems: const [
          FridgeItem(id: 'egg', name: 'Яйца', amount: 4, unit: Unit.pcs),
        ],
        pantryCatalog: const [
          PantryCatalogEntry(
            id: 'butter',
            name: 'Сливочное масло',
            canonicalName: 'масло сливочное',
            aliases: ['масло сливочное', 'сливочное масло'],
            category: 'oil',
            isStarter: true,
          ),
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
        ],
      ),
    );

    expect(generated, isNotEmpty);
    final eggDish = generated.firstWhere(
      (c) => c.recipe.anchorIngredients.any(
        (name) => name.toLowerCase().contains('яйц'),
      ),
      orElse: () => generated.first,
    );
    expect(eggDish.recipe.anchorIngredients.isNotEmpty, isTrue);
    expect(
      eggDish.recipe.steps.any(
        (step) => step.contains('масл') || step.contains('яйц'),
      ),
      isTrue,
    );
  });

  test('builds pasta dish from pasta and garlic with olive oil pantry', () {
    final generated = const OfflineChefEngine().generate(
      _request(
        fridgeItems: const [
          FridgeItem(id: 'pasta', name: 'Макароны', amount: 250, unit: Unit.g),
          FridgeItem(id: 'garlic', name: 'Чеснок', amount: 3, unit: Unit.pcs),
        ],
        pantryCatalog: const [
          PantryCatalogEntry(
            id: 'olive_oil',
            name: 'Оливковое масло',
            canonicalName: 'оливковое масло',
            aliases: ['оливковое масло'],
            category: 'oil',
            isStarter: true,
          ),
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
        ],
      ),
    );

    expect(generated, isNotEmpty);
    final pastaDish = generated.firstWhere(
      (c) => c.recipe.chefProfile == 'pasta',
      orElse: () => generated.first,
    );
    expect(pastaDish.recipe.chefProfile, 'pasta');
    expect(pastaDish.recipe.anchorIngredients, contains('Макароны'));
    expect(
      pastaDish.recipe.steps.any(
        (step) => step.contains('чеснок') || step.contains('масл'),
      ),
      isTrue,
    );
  });

  test('builds egg-tomato dish from tomato and egg with spice pantry', () {
    final generated = const OfflineChefEngine().generate(
      _request(
        fridgeItems: const [
          FridgeItem(id: 'tomato', name: 'Помидоры', amount: 4, unit: Unit.pcs),
          FridgeItem(id: 'egg', name: 'Яйца', amount: 4, unit: Unit.pcs),
        ],
        pantryCatalog: const [
          PantryCatalogEntry(
            id: 'oil',
            name: 'Масло',
            canonicalName: 'масло',
            aliases: ['масло'],
            category: 'oil',
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
          PantryCatalogEntry(
            id: 'salt',
            name: 'Соль',
            canonicalName: 'соль',
            aliases: ['соль'],
            category: 'basic',
            isStarter: true,
          ),
          PantryCatalogEntry(
            id: 'garlic',
            name: 'Чеснок',
            canonicalName: 'чеснок',
            aliases: ['чеснок'],
            category: 'spice',
            isStarter: true,
          ),
        ],
      ),
    );

    expect(generated, isNotEmpty);
    final dish = generated.firstWhere(
      (c) => c.recipe.title.contains('Шакшука'),
      orElse: () => generated.first,
    );
    expect(dish.recipe.anchorIngredients.isNotEmpty, isTrue);
    expect(
      dish.recipe.steps.any(
        (step) =>
            step.toLowerCase().contains('яйц') ||
            step.toLowerCase().contains('соус') ||
            step.toLowerCase().contains('помидор'),
      ),
      isTrue,
    );
  });

  test('builds potato-based dish from single potato ingredient', () {
    final generated = const OfflineChefEngine().generate(
      _request(
        fridgeItems: const [
          FridgeItem(
              id: 'potato', name: 'Картофель', amount: 6, unit: Unit.pcs),
        ],
        pantryCatalog: const [
          PantryCatalogEntry(
            id: 'butter',
            name: 'Сливочное масло',
            canonicalName: 'масло сливочное',
            aliases: ['масло сливочное', 'сливочное масло'],
            category: 'oil',
            isStarter: true,
          ),
          PantryCatalogEntry(
            id: 'milk',
            name: 'Молоко',
            canonicalName: 'молоко',
            aliases: ['молоко'],
            category: 'dairy',
            isStarter: true,
          ),
          PantryCatalogEntry(
            id: 'salt',
            name: 'Соль',
            canonicalName: 'соль',
            aliases: ['соль'],
            category: 'basic',
            isStarter: true,
          ),
        ],
      ),
    );

    expect(generated, isNotEmpty);
    final potatoDish = generated.firstWhere(
      (c) => c.recipe.anchorIngredients.any(
        (name) => name.toLowerCase().contains('картофел'),
      ),
      orElse: () => generated.first,
    );
    expect(potatoDish.recipe.anchorIngredients.isNotEmpty, isTrue);
    expect(
      potatoDish.recipe.steps.any(
        (step) =>
            step.contains('картофел') ||
            step.contains('вари') ||
            step.contains('масл'),
      ),
      isTrue,
    );
  });

  test('does not offer classic omelette when butter support is absent', () {
    final generated = const OfflineChefEngine().generate(
      _request(
        fridgeItems: const [
          FridgeItem(id: 'egg', name: 'Яйца', amount: 4, unit: Unit.pcs),
          FridgeItem(id: 'tomato', name: 'Помидоры', amount: 2, unit: Unit.pcs),
        ],
        pantryCatalog: const [
          PantryCatalogEntry(
            id: 'oil',
            name: 'Масло',
            canonicalName: 'масло',
            aliases: ['масло'],
            category: 'oil',
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
          PantryCatalogEntry(
            id: 'garlic',
            name: 'Чеснок',
            canonicalName: 'чеснок',
            aliases: ['чеснок'],
            category: 'spice',
            isStarter: true,
          ),
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
        ],
      ),
    );

    expect(generated, isNotEmpty);
    expect(
      generated.any(
          (candidate) => candidate.recipe.title.contains('Омлет классический')),
      isFalse,
    );
    final eggDish = generated.firstWhere(
      (candidate) => candidate.recipe.anchorIngredients.any(
        (name) => name.toLowerCase().contains('яйц'),
      ),
      orElse: () => generated.first,
    );
    expect(
      eggDish.recipe.steps.any((step) => step.toLowerCase().contains('сливоч')),
      isFalse,
    );
  });

  test('does not offer potato puree when dairy support is absent', () {
    final generated = const OfflineChefEngine().generate(
      _request(
        fridgeItems: const [
          FridgeItem(
              id: 'potato', name: 'Картофель', amount: 6, unit: Unit.pcs),
          FridgeItem(id: 'egg', name: 'Яйца', amount: 3, unit: Unit.pcs),
        ],
        pantryCatalog: const [
          PantryCatalogEntry(
            id: 'oil',
            name: 'Масло',
            canonicalName: 'масло',
            aliases: ['масло'],
            category: 'oil',
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
        ],
      ),
    );

    expect(generated, isNotEmpty);
    expect(
      generated.any(
          (candidate) => candidate.recipe.title.contains('Картофельное пюре')),
      isFalse,
    );
    final potatoDish = generated.firstWhere(
      (candidate) => candidate.recipe.anchorIngredients.any(
        (name) => name.toLowerCase().contains('картофел'),
      ),
      orElse: () => generated.first,
    );
    expect(
      potatoDish.recipe.steps.any(
        (step) =>
            step.toLowerCase().contains('молок') ||
            step.toLowerCase().contains('сливоч'),
      ),
      isFalse,
    );
  });
}

OfflineChefRequest _request({
  List<Recipe> baseRecipes = const [],
  required List<FridgeItem> fridgeItems,
  List<ShelfItem> shelfItems = const [],
  List<PantryCatalogEntry>? pantryCatalog,
  List<ProductCatalogEntry>? productCatalog,
  TasteProfile tasteProfile = const TasteProfile.empty(),
  int seed = 0,
}) {
  return OfflineChefRequest(
    baseRecipes: baseRecipes,
    fridgeItems: fridgeItems,
    shelfItems: shelfItems,
    tasteProfile: tasteProfile,
    productCatalog: productCatalog ??
        const [
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
          ProductCatalogEntry(
            id: 'beetroot',
            name: 'Свекла',
            canonicalName: 'свекла',
            synonyms: ['свекла', 'свёкла', 'вареная свекла'],
            defaultUnit: Unit.pcs,
          ),
          ProductCatalogEntry(
            id: 'cucumber',
            name: 'Огурцы',
            canonicalName: 'огурец',
            synonyms: ['огурец', 'соленые огурцы', 'маринованные огурцы'],
            defaultUnit: Unit.pcs,
          ),
          ProductCatalogEntry(
            id: 'sausage',
            name: 'Колбаса',
            canonicalName: 'колбаса',
            synonyms: ['колбаса', 'докторская колбаса'],
            defaultUnit: Unit.g,
          ),
          ProductCatalogEntry(
            id: 'sausages',
            name: 'Сосиски',
            canonicalName: 'сосиски',
            synonyms: ['сосиски'],
            defaultUnit: Unit.g,
          ),
          ProductCatalogEntry(
            id: 'peas',
            name: 'Горошек',
            canonicalName: 'горошек',
            synonyms: ['горошек', 'зеленый горошек'],
            defaultUnit: Unit.g,
          ),
          ProductCatalogEntry(
            id: 'pepper',
            name: 'Перец сладкий',
            canonicalName: 'перец сладкий',
            synonyms: ['болгарский перец'],
            defaultUnit: Unit.pcs,
          ),
          ProductCatalogEntry(
            id: 'broccoli',
            name: 'Брокколи',
            canonicalName: 'брокколи',
            synonyms: [],
            defaultUnit: Unit.g,
          ),
          ProductCatalogEntry(
            id: 'zucchini',
            name: 'Кабачок',
            canonicalName: 'кабачок',
            synonyms: [],
            defaultUnit: Unit.pcs,
          ),
          ProductCatalogEntry(
            id: 'garlic',
            name: 'Чеснок',
            canonicalName: 'чеснок',
            synonyms: [],
            defaultUnit: Unit.pcs,
          ),
          ProductCatalogEntry(
            id: 'fish',
            name: 'Рыба',
            canonicalName: 'рыба',
            synonyms: [],
            defaultUnit: Unit.g,
          ),
          ProductCatalogEntry(
            id: 'tuna',
            name: 'Тунец',
            canonicalName: 'тунец',
            synonyms: [],
            defaultUnit: Unit.g,
          ),
          ProductCatalogEntry(
            id: 'beans',
            name: 'Фасоль',
            canonicalName: 'фасоль',
            synonyms: [],
            defaultUnit: Unit.g,
          ),
          ProductCatalogEntry(
            id: 'corn',
            name: 'Кукуруза',
            canonicalName: 'кукуруза',
            synonyms: [],
            defaultUnit: Unit.g,
          ),
          ProductCatalogEntry(
            id: 'lentils',
            name: 'Чечевица',
            canonicalName: 'чечевица',
            synonyms: [],
            defaultUnit: Unit.g,
          ),
          ProductCatalogEntry(
            id: 'mince',
            name: 'Фарш',
            canonicalName: 'фарш',
            synonyms: ['котлеты', 'домашние котлеты'],
            defaultUnit: Unit.g,
          ),
          ProductCatalogEntry(
            id: 'liver',
            name: 'Печень',
            canonicalName: 'печень',
            synonyms: ['печень', 'куриная печень'],
            defaultUnit: Unit.g,
          ),
          ProductCatalogEntry(
            id: 'cabbage',
            name: 'Капуста',
            canonicalName: 'капуста',
            synonyms: [],
            defaultUnit: Unit.g,
          ),
          ProductCatalogEntry(
            id: 'olives',
            name: 'Оливки',
            canonicalName: 'оливки',
            synonyms: ['оливки', 'маслины'],
            defaultUnit: Unit.g,
          ),
          ProductCatalogEntry(
            id: 'millet',
            name: 'Пшено',
            canonicalName: 'пшено',
            synonyms: ['пшено', 'пшенная крупа'],
            defaultUnit: Unit.g,
          ),
          ProductCatalogEntry(
            id: 'semolina',
            name: 'Манная крупа',
            canonicalName: 'манная крупа',
            synonyms: ['манка', 'манная крупа'],
            defaultUnit: Unit.g,
          ),
          ProductCatalogEntry(
            id: 'oats',
            name: 'Овсяные хлопья',
            canonicalName: 'овсяные хлопья',
            synonyms: ['овсянка'],
            defaultUnit: Unit.g,
          ),
          ProductCatalogEntry(
            id: 'cottage_cheese',
            name: 'Творог',
            canonicalName: 'творог',
            synonyms: [],
            defaultUnit: Unit.g,
          ),
          ProductCatalogEntry(
            id: 'yogurt',
            name: 'Йогурт',
            canonicalName: 'йогурт',
            synonyms: [],
            defaultUnit: Unit.ml,
          ),
          ProductCatalogEntry(
            id: 'kefir',
            name: 'Кефир',
            canonicalName: 'кефир',
            synonyms: [],
            defaultUnit: Unit.ml,
          ),
          ProductCatalogEntry(
            id: 'kvass',
            name: 'Квас',
            canonicalName: 'квас',
            synonyms: ['домашний квас'],
            defaultUnit: Unit.ml,
          ),
          ProductCatalogEntry(
            id: 'sour_cream',
            name: 'Сметана',
            canonicalName: 'сметана',
            synonyms: [],
            defaultUnit: Unit.g,
          ),
          ProductCatalogEntry(
            id: 'milk',
            name: 'Молоко',
            canonicalName: 'молоко',
            synonyms: [],
            defaultUnit: Unit.ml,
          ),
          ProductCatalogEntry(
            id: 'butter',
            name: 'Сливочное масло',
            canonicalName: 'масло сливочное',
            synonyms: ['сливочное масло'],
            defaultUnit: Unit.g,
          ),
          ProductCatalogEntry(
            id: 'flour',
            name: 'Мука',
            canonicalName: 'мука',
            synonyms: ['мука'],
            defaultUnit: Unit.g,
          ),
          ProductCatalogEntry(
            id: 'tomato_paste',
            name: 'Томатная паста',
            canonicalName: 'томатная паста',
            synonyms: ['томатная паста'],
            defaultUnit: Unit.g,
          ),
          ProductCatalogEntry(
            id: 'beef',
            name: 'Говядина',
            canonicalName: 'говядина',
            synonyms: ['говядина'],
            defaultUnit: Unit.g,
          ),
          ProductCatalogEntry(
            id: 'pork',
            name: 'Свинина',
            canonicalName: 'свинина',
            synonyms: ['свинина'],
            defaultUnit: Unit.g,
          ),
          ProductCatalogEntry(
            id: 'pearl_barley',
            name: 'Перловка',
            canonicalName: 'перловка',
            synonyms: ['перловка', 'перловая крупа'],
            defaultUnit: Unit.g,
          ),
          ProductCatalogEntry(
            id: 'apple',
            name: 'Яблоко',
            canonicalName: 'яблоко',
            synonyms: [],
            defaultUnit: Unit.pcs,
          ),
          ProductCatalogEntry(
            id: 'banana',
            name: 'Банан',
            canonicalName: 'банан',
            synonyms: [],
            defaultUnit: Unit.pcs,
          ),
          ProductCatalogEntry(
            id: 'orange',
            name: 'Апельсин',
            canonicalName: 'апельсин',
            synonyms: [],
            defaultUnit: Unit.pcs,
          ),
          ProductCatalogEntry(
            id: 'lemon',
            name: 'Лимон',
            canonicalName: 'лимон',
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
          ProductCatalogEntry(
            id: 'greens',
            name: 'Зелень',
            canonicalName: 'зелень',
            synonyms: ['зелень', 'зеленый лук'],
            defaultUnit: Unit.g,
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
