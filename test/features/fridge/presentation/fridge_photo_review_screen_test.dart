import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/fridge/data/fridge_repo.dart';
import 'package:help_to_cook/features/fridge/data/product_catalog_repo.dart';
import 'package:help_to_cook/features/fridge/data/product_search_service.dart';
import 'package:help_to_cook/features/fridge/data/user_product_memory_repo.dart';
import 'package:help_to_cook/features/fridge/domain/detected_product_draft.dart';
import 'package:help_to_cook/features/fridge/domain/fridge_item.dart';
import 'package:help_to_cook/features/fridge/domain/photo_import_result.dart';
import 'package:help_to_cook/features/fridge/domain/product_search_suggestion.dart';
import 'package:help_to_cook/features/fridge/presentation/fridge_photo_review_screen.dart';

void main() {
  testWidgets('shows default merge option for duplicates', (tester) async {
    final result = PhotoImportResult(
      imagePath: '/tmp/test.jpg',
      drafts: const [
        DetectedProductDraft(
          id: 'd1',
          name: 'Молоко',
          amount: 1,
          unit: Unit.l,
          confidence: 0.8,
          rawTokens: ['молоко'],
          source: DetectionSource.local,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fridgeRepoProvider.overrideWithValue(_FakeFridgeRepo()),
          productSearchServiceProvider.overrideWithValue(
            _FakeProductSearchService(),
          ),
        ],
        child: MaterialApp(
          home: FridgePhotoReviewScreen(result: result),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Объединить с "Молоко"'), findsOneWidget);
  });

  testWidgets('shows candidate chips for detected products', (tester) async {
    final result = PhotoImportResult(
      imagePath: '/tmp/test.jpg',
      drafts: const [
        DetectedProductDraft(
          id: 'd2',
          name: 'Молоко',
          amount: 1,
          unit: Unit.l,
          confidence: 0.8,
          rawTokens: ['молоко'],
          source: DetectionSource.local,
          candidateMatches: [
            ProductSearchSuggestion(
              id: 'milk',
              catalogId: 'milk',
              name: 'Молоко',
              matchedText: 'молоко',
              defaultUnit: Unit.l,
              source: ProductSuggestionSource.catalog,
              score: 0.9,
            ),
            ProductSearchSuggestion(
              id: 'kefir',
              catalogId: 'kefir',
              name: 'Кефир',
              matchedText: 'кефир',
              defaultUnit: Unit.l,
              source: ProductSuggestionSource.catalog,
              score: 0.7,
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fridgeRepoProvider.overrideWithValue(_FakeFridgeRepo()),
          productSearchServiceProvider.overrideWithValue(
            _FakeProductSearchService(),
          ),
        ],
        child: MaterialApp(
          home: FridgePhotoReviewScreen(result: result),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Кефир'), findsOneWidget);
  });
}

class _FakeFridgeRepo extends FridgeRepo {
  final Map<String, FridgeItem> _items = {
    'f1': const FridgeItem(
      id: 'f1',
      name: 'Молоко',
      amount: 0.5,
      unit: Unit.l,
    ),
  };

  _FakeFridgeRepo() : super(boxName: 'test');

  @override
  List<FridgeItem> getAll() => _items.values.toList();

  @override
  Future<void> upsert(FridgeItem item) async {
    _items[item.id] = item;
  }

  @override
  Future<void> delete(String id) async {
    _items.remove(id);
  }
}

class _FakeProductSearchService extends ProductSearchService {
  _FakeProductSearchService()
      : super(
          catalogRepo: const ProductCatalogRepo(),
          userProductMemoryRepo: const UserProductMemoryRepo(),
        );

  @override
  Future<List<ProductSearchSuggestion>> recentSuggestions({int limit = 8}) async {
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
