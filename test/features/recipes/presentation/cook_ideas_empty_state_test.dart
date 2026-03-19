import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/theme/app_theme.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/fridge/data/fridge_repo.dart';
import 'package:help_to_cook/features/fridge/data/user_product_memory_repo.dart';
import 'package:help_to_cook/features/fridge/domain/fridge_item.dart';
import 'package:help_to_cook/features/fridge/domain/product_catalog_entry.dart';
import 'package:help_to_cook/features/recipes/domain/recipe.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_ingredient.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_match.dart';
import 'package:help_to_cook/features/recipes/domain/taste_profile.dart';
import 'package:help_to_cook/features/recipes/presentation/cook_ideas_screen.dart';
import 'package:help_to_cook/features/recipes/presentation/providers.dart';
import 'package:help_to_cook/features/shelf/data/shelf_repo.dart';
import 'package:help_to_cook/features/shelf/domain/pantry_catalog_entry.dart';
import 'package:help_to_cook/features/shelf/domain/shelf_item.dart';

void main() {
  testWidgets('empty cook screen shows CTA to fridge', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recipesProvider.overrideWith((ref) async => const <Recipe>[]),
          productCatalogProvider.overrideWith((ref) async => const []),
          recipeMatchesProvider.overrideWith((ref) => const <RecipeMatch>[]),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CookIdeasScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Перейти в холодильник'), findsOneWidget);
  });

  testWidgets('cook screen stays empty when fridge has no products',
      (tester) async {
    const recipe = Recipe(
      id: 'soup',
      title: 'Куриный суп',
      timeMin: 45,
      tags: ['soup'],
      servingsBase: 2,
      ingredients: [
        RecipeIngredient(name: 'Курица', amount: 400, unit: Unit.g),
      ],
      steps: ['Шаг 1', 'Шаг 2'],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recipesProvider.overrideWith((ref) async => const [recipe]),
          productCatalogProvider.overrideWith(
            (ref) async => const [
              ProductCatalogEntry(
                id: 'chicken',
                name: 'Курица',
                canonicalName: 'курица',
                synonyms: ['курица'],
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
          tasteProfileProvider
              .overrideWith((ref) => const TasteProfile.empty()),
          fridgeRepoProvider.overrideWithValue(_StaticFridgeRepo()),
          userProductMemoryRepoProvider
              .overrideWithValue(const _NoopUserProductMemoryRepo()),
          shelfRepoProvider.overrideWithValue(
            _StaticShelfRepo(
              const [ShelfItem(id: 'salt', name: 'Соль', inStock: true)],
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CookIdeasScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Перейти в холодильник'), findsOneWidget);
    expect(find.text('Лучшее блюдо сегодня'), findsNothing);
  });
}

class _StaticFridgeRepo extends FridgeRepo {
  _StaticFridgeRepo() : super(boxName: 'test');

  @override
  List<FridgeItem> getAll() => const [];
}

class _StaticShelfRepo extends ShelfRepo {
  final List<ShelfItem> _items;

  _StaticShelfRepo(this._items) : super(boxName: 'test');

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
