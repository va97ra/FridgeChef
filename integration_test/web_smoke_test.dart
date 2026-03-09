import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';

import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/fridge/data/fridge_repo.dart';
import 'package:help_to_cook/features/fridge/data/product_catalog_repo.dart';
import 'package:help_to_cook/features/fridge/data/product_search_service.dart';
import 'package:help_to_cook/features/fridge/data/user_product_memory_repo.dart';
import 'package:help_to_cook/features/fridge/domain/fridge_item.dart';
import 'package:help_to_cook/features/fridge/domain/product_catalog_entry.dart';
import 'package:help_to_cook/features/fridge/domain/product_search_suggestion.dart';
import 'package:help_to_cook/features/fridge/domain/user_product_memory_entry.dart';
import 'package:help_to_cook/features/fridge/presentation/fridge_list_screen.dart';
import 'package:help_to_cook/features/recipes/domain/recipe.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_ingredient.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_match.dart';
import 'package:help_to_cook/features/recipes/data/generated_recipe_draft_parser.dart';
import 'package:help_to_cook/features/recipes/data/user_recipes_repo.dart';
import 'package:help_to_cook/features/recipes/presentation/cook_ideas_screen.dart';
import 'package:help_to_cook/features/recipes/presentation/providers.dart';
import 'package:help_to_cook/features/shelf/data/pantry_catalog_repo.dart';
import 'package:help_to_cook/features/shelf/data/pantry_search_service.dart';
import 'package:help_to_cook/features/shelf/data/shelf_repo.dart';
import 'package:help_to_cook/features/shelf/domain/pantry_catalog_entry.dart';
import 'package:help_to_cook/features/shelf/domain/shelf_item.dart';
import 'package:help_to_cook/features/shelf/presentation/shelf_list_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('fridge add and save works in browser smoke', (tester) async {
    final fridgeRepo = _FakeFridgeRepo();

    await _pumpSmokeScreen(
      tester,
      const FridgeListScreen(),
      overrides: [
        fridgeRepoProvider.overrideWithValue(fridgeRepo),
        userProductMemoryRepoProvider.overrideWithValue(
          const _NoopUserProductMemoryRepo(),
        ),
        productSearchServiceProvider.overrideWithValue(
          _FakeProductSearchService(),
        ),
      ],
    );

    await tester.tap(find.byTooltip('Добавить продукт'));
    await tester.pumpAndSettle();

    await tester.enterText(_fieldWithLabel('Название продукта'), 'Молоко');
    await tester.enterText(_fieldWithLabel('Количество'), '1');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(fridgeRepo.items, hasLength(1));
    expect(fridgeRepo.items.single.name, 'Молоко');
    expect(find.text('Мой холодильник'), findsOneWidget);
  });

  testWidgets('fridge edit and delete works in browser smoke', (tester) async {
    final fridgeRepo = _FakeFridgeRepo(
      initialItems: [
        FridgeItem(
          id: 'milk',
          name: 'Молоко',
          amount: 1,
          unit: Unit.l,
        ),
      ],
    );

    await _pumpSmokeScreen(
      tester,
      const FridgeListScreen(),
      overrides: [
        fridgeRepoProvider.overrideWithValue(fridgeRepo),
        userProductMemoryRepoProvider.overrideWithValue(
          const _NoopUserProductMemoryRepo(),
        ),
        productSearchServiceProvider.overrideWithValue(
          _FakeProductSearchService(),
        ),
      ],
    );

    await tester.tap(find.text('Молоко').first);
    await tester.pumpAndSettle();

    await tester.enterText(_fieldWithLabel('Количество'), '2');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(fridgeRepo.items, hasLength(1));
    expect(fridgeRepo.items.single.amount, 2);
    expect(find.text('Мой холодильник'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
    await tester.pumpAndSettle();

    expect(fridgeRepo.items, isEmpty);
    expect(find.text('Холодильник пока пуст'), findsOneWidget);
  });

  testWidgets('shelf add works in browser smoke', (tester) async {
    final shelfRepo = _FakeShelfRepo();

    await _pumpSmokeScreen(
      tester,
      const ShelfListScreen(),
      overrides: [
        shelfRepoProvider.overrideWithValue(shelfRepo),
        pantrySearchServiceProvider.overrideWithValue(
          _FakePantrySearchService(),
        ),
      ],
    );

    await tester.tap(find.text('Добавить на полку'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Соль').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(shelfRepo.items, hasLength(1));
    expect(shelfRepo.items.single.name, 'Соль');
    expect(find.text('Полка'), findsOneWidget);
  });

  testWidgets('cook flow opens recipe detail in browser smoke', (tester) async {
    final bestRecipe = Recipe(
      id: 'best',
      title: 'Шакшука',
      timeMin: 18,
      tags: const ['one_pan'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Яйцо', amount: 4, unit: Unit.pcs),
        RecipeIngredient(name: 'Помидор', amount: 200, unit: Unit.g),
      ],
      steps: const ['Шаг 1', 'Шаг 2'],
      description: 'Яркое блюдо из яиц и томатов.',
    );
    final secondRecipe = Recipe(
      id: 'second',
      title: 'Омлет',
      timeMin: 10,
      tags: const ['quick'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Яйцо', amount: 2, unit: Unit.pcs),
      ],
      steps: const ['Шаг 1'],
    );

    await _pumpSmokeScreen(
      tester,
      const CookIdeasScreen(),
      overrides: [
        recipesProvider.overrideWith((ref) async => [bestRecipe, secondRecipe]),
        productCatalogProvider.overrideWith(
          (ref) async => const [
            ProductCatalogEntry(
              id: 'egg',
              name: 'Яйца',
              synonyms: ['яйцо', 'яйца'],
              defaultUnit: Unit.pcs,
            ),
            ProductCatalogEntry(
              id: 'tomato',
              name: 'Помидоры',
              synonyms: ['помидор', 'томаты'],
              defaultUnit: Unit.g,
            ),
          ],
        ),
        pantryCatalogProvider.overrideWith(
          (ref) async => const [
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
        recipeMatchesProvider.overrideWith(
          (ref) => [
            RecipeMatch(
              recipe: bestRecipe,
              source: RecipeMatchSource.generated,
              score: 0.94,
              why: const [
                'все продукты есть дома',
                'сильное сочетание яйцо + помидор'
              ],
              missingIngredients: const [],
              matchedCount: 3,
              totalCount: 3,
              matchedRequired: 3,
              totalRequired: 3,
              matchedOptional: 0,
              totalOptional: 0,
            ),
            RecipeMatch(
              recipe: secondRecipe,
              score: 0.78,
              why: const ['готовится быстро'],
              missingIngredients: const [],
              matchedCount: 2,
              totalCount: 2,
              matchedRequired: 2,
              totalRequired: 2,
              matchedOptional: 0,
              totalOptional: 0,
            ),
          ],
        ),
      ],
    );

    await tester.tap(
      find.bySemanticsLabel(RegExp('Открыть лучший рецепт Шакшука')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Шакшука'), findsWidgets);
    expect(find.text('О блюде'), findsOneWidget);
  });

  testWidgets('saved recipe rename and delete works in browser smoke',
      (tester) async {
    final baseRecipe = Recipe(
      id: 'base',
      title: 'Шакшука',
      timeMin: 18,
      tags: const ['one_pan'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Яйцо', amount: 4, unit: Unit.pcs),
      ],
      steps: const ['Шаг 1', 'Шаг 2'],
    );
    final savedRecipe = Recipe(
      id: 'saved_1',
      title: 'Шеф-омлет',
      timeMin: 10,
      tags: const ['quick', 'generated_local'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Яйцо', amount: 2, unit: Unit.pcs),
      ],
      steps: const ['Шаг 1'],
      source: RecipeSource.generatedSaved,
      isUserEditable: true,
    );
    final userRepo = _FakeUserRecipesRepo([savedRecipe]);

    await _pumpSmokeScreen(
      tester,
      const CookIdeasScreen(),
      overrides: [
        userRecipesRepoProvider.overrideWithValue(userRepo),
        recipesProvider.overrideWith(
          (ref) async => [baseRecipe, ...await userRepo.getAllUserRecipes()],
        ),
        productCatalogProvider.overrideWith(
          (ref) async => const [
            ProductCatalogEntry(
              id: 'egg',
              name: 'Яйца',
              synonyms: ['яйцо', 'яйца'],
              defaultUnit: Unit.pcs,
            ),
          ],
        ),
        pantryCatalogProvider.overrideWith(
          (ref) async => const [
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
        recipeMatchesProvider.overrideWith((ref) {
          final recipes = ref.watch(recipesProvider).valueOrNull ?? const <Recipe>[];
          return recipes.map((recipe) {
            final isSaved = recipe.id == savedRecipe.id;
            return RecipeMatch(
              recipe: recipe,
              source: isSaved ? RecipeMatchSource.base : RecipeMatchSource.generated,
              score: isSaved ? 0.78 : 0.94,
              why: isSaved
                  ? const ['сохранённый вариант под рукой']
                  : const ['все продукты есть дома'],
              missingIngredients: const [],
              matchedCount: recipe.ingredients.length,
              totalCount: recipe.ingredients.length,
              matchedRequired: recipe.ingredients.length,
              totalRequired: recipe.ingredients.length,
              matchedOptional: 0,
              totalOptional: 0,
            );
          }).toList();
        }),
      ],
    );

    await tester.scrollUntilVisible(
      find.byTooltip('Действия рецепта Шеф-омлет'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Действия рецепта Шеф-омлет'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Переименовать'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'Омлет шефа');
    await tester.tap(find.text('Сохранить').last);
    await tester.pumpAndSettle();

    expect(userRepo.recipes.single.title, 'Омлет шефа');
    await tester.scrollUntilVisible(
      find.byTooltip('Действия рецепта Омлет шефа'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Омлет шефа'), findsOneWidget);

    await tester.tap(find.byTooltip('Действия рецепта Омлет шефа'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить').last);
    await tester.pumpAndSettle();

    expect(userRepo.recipes, isEmpty);
    expect(find.text('Омлет шефа', skipOffstage: false), findsNothing);
  });
}

Future<void> _pumpSmokeScreen(
  WidgetTester tester,
  Widget screen, {
  required List<Override> overrides,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _fieldWithLabel(String label) {
  return find.bySemanticsLabel(label);
}

class _FakeFridgeRepo extends FridgeRepo {
  _FakeFridgeRepo({List<FridgeItem>? initialItems})
      : items = List<FridgeItem>.from(initialItems ?? const []),
        super(boxName: 'test');

  final List<FridgeItem> items;

  @override
  List<FridgeItem> getAll() => List<FridgeItem>.from(items);

  @override
  Future<void> upsert(FridgeItem item) async {
    items.removeWhere((existing) => existing.id == item.id);
    items.add(item);
  }

  @override
  Future<void> delete(String id) async {
    items.removeWhere((existing) => existing.id == id);
  }
}

class _FakeShelfRepo extends ShelfRepo {
  _FakeShelfRepo() : super(boxName: 'test');

  final List<ShelfItem> items = [];

  @override
  List<ShelfItem> getAll() => List<ShelfItem>.from(items);

  @override
  Future<void> upsert(ShelfItem item) async {
    items.removeWhere((existing) => existing.id == item.id);
    items.add(item);
  }

  @override
  Future<void> delete(String id) async {
    items.removeWhere((existing) => existing.id == id);
  }

  @override
  Future<void> replaceAll(List<ShelfItem> nextItems) async {
    items
      ..clear()
      ..addAll(nextItems);
  }
}

class _FakeUserRecipesRepo extends UserRecipesRepo {
  _FakeUserRecipesRepo(List<Recipe> initialRecipes)
      : recipes = List<Recipe>.from(initialRecipes),
        super(
          boxName: 'test',
          parser: const GeneratedRecipeDraftParser(),
        );

  final List<Recipe> recipes;

  @override
  Future<List<Recipe>> getAllUserRecipes() async {
    return List<Recipe>.from(recipes);
  }

  @override
  Future<void> renameUserRecipe(String id, String newTitle) async {
    final index = recipes.indexWhere((recipe) => recipe.id == id);
    if (index == -1) {
      return;
    }
    recipes[index] = recipes[index].copyWith(
      title: newTitle.trim(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteUserRecipe(String id) async {
    recipes.removeWhere((recipe) => recipe.id == id);
  }
}

class _NoopUserProductMemoryRepo extends UserProductMemoryRepo {
  const _NoopUserProductMemoryRepo();

  @override
  Future<List<UserProductMemoryEntry>> loadAll() async {
    return <UserProductMemoryEntry>[];
  }

  @override
  Future<void> recordProduct({
    required String name,
    required Unit unit,
    required double amount,
    String? productId,
  }) async {}
}

class _FakeProductSearchService extends ProductSearchService {
  _FakeProductSearchService()
      : super(
          catalogRepo: const ProductCatalogRepo(),
          userProductMemoryRepo: const UserProductMemoryRepo(),
        );

  @override
  Future<List<ProductSearchSuggestion>> recentSuggestions(
      {int limit = 8}) async {
    return const [];
  }

  @override
  Future<List<ProductSearchSuggestion>> search(
    String query, {
    int limit = 8,
  }) async {
    return const [];
  }
}

class _FakePantrySearchService extends PantrySearchService {
  _FakePantrySearchService()
      : super(
          catalogRepo: const PantryCatalogRepo(),
        );

  static const _entries = [
    PantryCatalogEntry(
      id: 'salt',
      name: 'Соль',
      canonicalName: 'соль',
      aliases: ['соль'],
      category: 'basic',
      isStarter: true,
    ),
  ];

  @override
  Future<List<PantryCatalogEntry>> starterSuggestions({int limit = 10}) async {
    return _entries.take(limit).toList();
  }

  @override
  Future<List<PantryCatalogEntry>> search(
    String query, {
    int limit = 8,
  }) async {
    if (query.trim().isEmpty) {
      return starterSuggestions(limit: limit);
    }
    return _entries
        .where(
          (entry) => entry.name.toLowerCase().contains(query.toLowerCase()),
        )
        .take(limit)
        .toList();
  }
}
