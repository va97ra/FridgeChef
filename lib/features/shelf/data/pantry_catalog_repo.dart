import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/pantry_catalog_entry.dart';

final pantryCatalogRepoProvider = Provider<PantryCatalogRepo>((ref) {
  return const PantryCatalogRepo();
});

class PantryCatalogRepo {
  static const _catalogPath = 'assets/pantry/catalog_ru.json';
  static List<PantryCatalogEntry>? _cachedCatalog;

  const PantryCatalogRepo();

  Future<List<PantryCatalogEntry>> loadCatalog() async {
    final cached = _cachedCatalog;
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final jsonText = await rootBundle.loadString(_catalogPath);
    final rawList = jsonDecode(jsonText) as List<dynamic>;
    final catalog = rawList
        .map(
          (entry) => PantryCatalogEntry.fromJson(entry as Map<String, dynamic>),
        )
        .toList();
    _cachedCatalog = catalog;
    return catalog;
  }
}
