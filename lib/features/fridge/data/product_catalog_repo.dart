import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/product_catalog_entry.dart';

final productCatalogRepoProvider = Provider<ProductCatalogRepo>((ref) {
  return const ProductCatalogRepo();
});

class ProductCatalogRepo {
  static const _catalogPath = 'assets/products/catalog_ru.json';
  static List<ProductCatalogEntry>? _cachedCatalog;

  const ProductCatalogRepo();

  Future<List<ProductCatalogEntry>> loadCatalog() async {
    final cached = _cachedCatalog;
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final jsonText = await rootBundle.loadString(_catalogPath);
    final rawList = jsonDecode(jsonText) as List<dynamic>;
    final catalog = rawList
        .map(
          (entry) =>
              ProductCatalogEntry.fromJson(entry as Map<String, dynamic>),
        )
        .toList();
    _cachedCatalog = catalog;
    return catalog;
  }
}
