import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/photo_import_utils.dart';
import '../domain/product_catalog_entry.dart';
import '../domain/product_search_suggestion.dart';
import '../domain/user_product_memory_entry.dart';
import 'product_catalog_repo.dart';
import 'user_product_memory_repo.dart';

final productSearchServiceProvider = Provider<ProductSearchService>((ref) {
  return ProductSearchService(
    catalogRepo: ref.watch(productCatalogRepoProvider),
    userProductMemoryRepo: ref.watch(userProductMemoryRepoProvider),
  );
});

class ProductSearchService {
  final ProductCatalogRepo catalogRepo;
  final UserProductMemoryRepo userProductMemoryRepo;

  const ProductSearchService({
    required this.catalogRepo,
    required this.userProductMemoryRepo,
  });

  Future<List<ProductSearchSuggestion>> recentSuggestions({
    int limit = 8,
  }) async {
    final catalog = await catalogRepo.loadCatalog();
    final memory = await userProductMemoryRepo.loadAll();
    final recent = _recentMemorySuggestions(memory);
    if (recent.length >= limit) {
      return recent.take(limit).toList();
    }

    final usedIds = recent.map((entry) => entry.id).toSet();
    final catalogFallback = catalog
        .where((entry) => !usedIds.contains(entry.id))
        .take(limit - recent.length)
        .map(
          (entry) => ProductSearchSuggestion(
            id: entry.id,
            catalogId: entry.id,
            name: entry.name,
            matchedText: entry.name,
            defaultUnit: entry.defaultUnit,
            source: ProductSuggestionSource.catalog,
            score: 0.35,
          ),
        );

    return [...recent, ...catalogFallback].take(limit).toList();
  }

  Future<List<ProductSearchSuggestion>> search(
    String query, {
    int limit = 8,
  }) async {
    final normalized = normalizeProductToken(query);
    if (normalized.isEmpty) {
      return recentSuggestions(limit: limit);
    }

    final catalog = await catalogRepo.loadCatalog();
    final memory = await userProductMemoryRepo.loadAll();
    final catalogMatches =
        findCatalogMatches(normalized, catalog, limit: limit * 2);

    final ranked = <String, ProductSearchSuggestion>{};

    for (final memoryEntry in memory) {
      final suggestion = _scoreMemoryEntry(memoryEntry, normalized, catalog);
      if (suggestion == null) {
        continue;
      }
      ranked[suggestion.id] = suggestion;
    }

    for (final entry in catalogMatches) {
      final boosted = _applyMemoryBoost(entry, memory);
      final existing = ranked[boosted.id];
      if (existing == null || boosted.score > existing.score) {
        ranked[boosted.id] = boosted;
      }
    }

    final results = ranked.values.toList()
      ..sort((a, b) {
        final scoreCompare = b.score.compareTo(a.score);
        if (scoreCompare != 0) {
          return scoreCompare;
        }
        return a.name.compareTo(b.name);
      });
    return results.take(limit).toList();
  }

  List<ProductSearchSuggestion> _recentMemorySuggestions(
    List<UserProductMemoryEntry> memory,
  ) {
    return memory
        .where((entry) => entry.name.trim().isNotEmpty)
        .take(8)
        .map((entry) {
      return ProductSearchSuggestion(
        id: entry.productId ?? entry.key,
        catalogId: entry.productId,
        name: entry.name,
        matchedText: entry.name,
        defaultUnit: entry.lastUnit,
        source: ProductSuggestionSource.recent,
        score: 1.0 + (entry.frequency * 0.01),
        suggestedAmount: entry.lastAmount,
      );
    }).toList();
  }

  ProductSearchSuggestion? _scoreMemoryEntry(
    UserProductMemoryEntry entry,
    String normalizedQuery,
    List<ProductCatalogEntry> catalog,
  ) {
    final variants = <String>{
      normalizeProductToken(entry.name),
    };
    final catalogEntry = _findCatalogEntry(entry, catalog);
    if (catalogEntry != null) {
      variants.add(normalizeProductToken(catalogEntry.name));
      variants.addAll(catalogEntry.synonyms.map(normalizeProductToken));
    }

    double? bestScore;
    String? bestMatch;
    for (final variant in variants) {
      final candidates = findCatalogMatches(
        normalizedQuery,
        [
          ProductCatalogEntry(
            id: entry.productId ?? entry.key,
            name: entry.name,
            synonyms: [variant],
            defaultUnit: entry.lastUnit,
          ),
        ],
        limit: 1,
      );
      if (candidates.isEmpty) {
        continue;
      }
      final score = candidates.first.score;
      if (bestScore == null || score > bestScore) {
        bestScore = score;
        bestMatch = candidates.first.matchedText;
      }
    }

    if (bestScore == null || bestMatch == null) {
      return null;
    }

    return ProductSearchSuggestion(
      id: entry.productId ?? entry.key,
      catalogId: entry.productId,
      name: entry.name,
      matchedText: bestMatch,
      defaultUnit: entry.lastUnit,
      source: ProductSuggestionSource.recent,
      score: bestScore + 0.18 + (entry.frequency * 0.01),
      suggestedAmount: entry.lastAmount,
    );
  }

  ProductSearchSuggestion _applyMemoryBoost(
    ProductSearchSuggestion suggestion,
    List<UserProductMemoryEntry> memory,
  ) {
    final normalizedName = normalizeProductToken(suggestion.name);
    UserProductMemoryEntry? memoryEntry;
    for (final entry in memory) {
      if (entry.productId == suggestion.catalogId ||
          normalizeProductToken(entry.name) == normalizedName) {
        memoryEntry = entry;
        break;
      }
    }
    if (memoryEntry == null) {
      return suggestion;
    }

    return ProductSearchSuggestion(
      id: suggestion.id,
      catalogId: memoryEntry.productId ?? suggestion.catalogId,
      name: suggestion.name,
      matchedText: suggestion.matchedText,
      defaultUnit: memoryEntry.lastUnit,
      source: ProductSuggestionSource.recent,
      score: suggestion.score + 0.15 + (memoryEntry.frequency * 0.01),
      suggestedAmount: memoryEntry.lastAmount,
    );
  }

  ProductCatalogEntry? _findCatalogEntry(
    UserProductMemoryEntry entry,
    List<ProductCatalogEntry> catalog,
  ) {
    final productId = entry.productId;
    if (productId == null || productId.isEmpty) {
      return null;
    }

    for (final catalogEntry in catalog) {
      if (catalogEntry.id == productId) {
        return catalogEntry;
      }
    }
    return null;
  }
}
