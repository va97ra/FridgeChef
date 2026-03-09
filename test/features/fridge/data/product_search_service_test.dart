import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/fridge/data/product_catalog_repo.dart';
import 'package:help_to_cook/features/fridge/data/product_search_service.dart';
import 'package:help_to_cook/features/fridge/data/user_product_memory_repo.dart';
import 'package:help_to_cook/features/fridge/domain/product_catalog_entry.dart';
import 'package:help_to_cook/features/fridge/domain/product_search_suggestion.dart';
import 'package:help_to_cook/features/fridge/domain/user_product_memory_entry.dart';

void main() {
  final catalog = [
    const ProductCatalogEntry(
      id: 'milk',
      name: 'Молоко',
      synonyms: ['молоко', 'milk'],
      defaultUnit: Unit.l,
    ),
    const ProductCatalogEntry(
      id: 'potato',
      name: 'Картофель',
      synonyms: ['картофель', 'картошка'],
      defaultUnit: Unit.g,
    ),
  ];

  test('returns catalog suggestion for partial query', () async {
    final service = ProductSearchService(
      catalogRepo: _FakeCatalogRepo(catalog),
      userProductMemoryRepo: const _FakeMemoryRepo([]),
    );

    final results = await service.search('моло');

    expect(results, isNotEmpty);
    expect(results.first.name, 'Молоко');
    expect(results.first.defaultUnit, Unit.l);
  });

  test('boosts recent user products above plain catalog matches', () async {
    final service = ProductSearchService(
      catalogRepo: _FakeCatalogRepo(catalog),
      userProductMemoryRepo: _FakeMemoryRepo([
        UserProductMemoryEntry(
          key: 'catalog:milk',
          name: 'Молоко',
          productId: 'milk',
          lastUnit: Unit.l,
          lastAmount: 2,
          frequency: 5,
          lastUsedAt: DateTime(2026, 3, 6),
        ),
      ]),
    );

    final results = await service.search('мол');

    expect(results, isNotEmpty);
    expect(results.first.name, 'Молоко');
    expect(results.first.source, ProductSuggestionSource.recent);
    expect(results.first.suggestedAmount, 2);
  });

  test('supports fuzzy match for misspelled query', () async {
    final service = ProductSearchService(
      catalogRepo: _FakeCatalogRepo(catalog),
      userProductMemoryRepo: const _FakeMemoryRepo([]),
    );

    final results = await service.search('картоф');

    expect(results, isNotEmpty);
    expect(results.first.name, 'Картофель');
  });
}

class _FakeCatalogRepo extends ProductCatalogRepo {
  final List<ProductCatalogEntry> catalog;

  const _FakeCatalogRepo(this.catalog);

  @override
  Future<List<ProductCatalogEntry>> loadCatalog() async => catalog;
}

class _FakeMemoryRepo extends UserProductMemoryRepo {
  final List<UserProductMemoryEntry> items;

  const _FakeMemoryRepo(this.items);

  @override
  Future<List<UserProductMemoryEntry>> loadAll() async => items;
}
