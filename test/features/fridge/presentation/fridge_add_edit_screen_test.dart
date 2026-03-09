import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:help_to_cook/core/utils/formatters.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/fridge/data/fridge_repo.dart';
import 'package:help_to_cook/features/fridge/data/product_catalog_repo.dart';
import 'package:help_to_cook/features/fridge/data/product_search_service.dart';
import 'package:help_to_cook/features/fridge/data/user_product_memory_repo.dart';
import 'package:help_to_cook/features/fridge/domain/fridge_item.dart';
import 'package:help_to_cook/features/fridge/domain/product_search_suggestion.dart';
import 'package:help_to_cook/features/fridge/presentation/fridge_add_edit_screen.dart';

void main() {
  testWidgets('shows suggestions and applies selected product defaults',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fridgeRepoProvider.overrideWithValue(_FakeFridgeRepo()),
          productSearchServiceProvider.overrideWithValue(
            _FakeProductSearchService(),
          ),
        ],
        child: const MaterialApp(
          home: FridgeAddEditScreen(),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'мол');
    await tester.pumpAndSettle();

    expect(find.text('Молоко'), findsAtLeastNWidgets(1));

    await tester.tap(find.text('Молоко').last);
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);
    expect(find.text('л'), findsWidgets);
  });

  testWidgets('quick expiry chips set expiry date without opening calendar',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fridgeRepoProvider.overrideWithValue(_FakeFridgeRepo()),
          productSearchServiceProvider.overrideWithValue(
            _FakeProductSearchService(),
          ),
        ],
        child: const MaterialApp(
          home: FridgeAddEditScreen(),
        ),
      ),
    );

    await tester.tap(find.text('Завтра'));
    await tester.pumpAndSettle();

    final expected = Formatters.formatDate(
      DateTime.now().add(const Duration(days: 1)),
    );
    expect(find.text(expected), findsOneWidget);
  });
}

class _FakeFridgeRepo extends FridgeRepo {
  _FakeFridgeRepo() : super(boxName: 'test');

  @override
  List<FridgeItem> getAll() => const [];
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
    return [
      const ProductSearchSuggestion(
        id: 'milk',
        catalogId: 'milk',
        name: 'Молоко',
        matchedText: 'молоко',
        defaultUnit: Unit.l,
        source: ProductSuggestionSource.catalog,
        score: 0.9,
        suggestedAmount: 2,
      ),
    ];
  }

  @override
  Future<List<ProductSearchSuggestion>> search(
    String query, {
    int limit = 8,
  }) async {
    if (query.toLowerCase().contains('мол')) {
      return [
        const ProductSearchSuggestion(
          id: 'milk',
          catalogId: 'milk',
          name: 'Молоко',
          matchedText: 'молоко',
          defaultUnit: Unit.l,
          source: ProductSuggestionSource.recent,
          score: 1.1,
          suggestedAmount: 2,
        ),
      ];
    }
    return const [];
  }
}
