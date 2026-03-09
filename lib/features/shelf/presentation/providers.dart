import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../fridge/domain/photo_import_utils.dart';
import '../domain/pantry_catalog_entry.dart';
import '../domain/shelf_item.dart';
import '../data/shelf_repo.dart';

class ShelfBatchUpdateResult {
  final int added;
  final int enabled;

  const ShelfBatchUpdateResult({
    required this.added,
    required this.enabled,
  });

  bool get isEmpty => added == 0 && enabled == 0;
}

class ShelfListNotifier extends StateNotifier<List<ShelfItem>> {
  final ShelfRepo _repo;

  ShelfListNotifier(this._repo) : super([]) {
    _load();
  }

  void _load() {
    state = _repo.getAll();
  }

  Future<void> addItem(ShelfItem item) async {
    await _repo.upsert(item);
    _load();
  }

  Future<void> updateItem(ShelfItem item) async {
    await _repo.upsert(item);
    _load();
  }

  Future<void> toggleItem(ShelfItem item) async {
    await _repo.upsert(item.copyWith(inStock: !item.inStock));
    _load();
  }

  Future<void> removeItem(String id) async {
    await _repo.delete(id);
    _load();
  }

  Future<ShelfBatchUpdateResult> addOrEnablePantryEntries(
    List<PantryCatalogEntry> entries,
  ) async {
    if (entries.isEmpty) {
      return const ShelfBatchUpdateResult(added: 0, enabled: 0);
    }

    final updated = [...state];
    var added = 0;
    var enabled = 0;

    for (final entry in entries) {
      final normalizedCanonical = normalizeProductToken(entry.canonicalName);
      final existingIndex = updated.indexWhere((item) {
        if (item.catalogId != null && item.catalogId == entry.id) {
          return true;
        }
        return normalizeProductToken(item.canonicalName) ==
                normalizedCanonical ||
            normalizeProductToken(item.name) ==
                normalizeProductToken(entry.name);
      });

      if (existingIndex == -1) {
        updated.add(
          ShelfItem(
            id: 'pantry:${entry.id}',
            name: entry.name,
            inStock: true,
            catalogId: entry.id,
            canonicalName: entry.canonicalName,
            category: entry.category,
            supportCanonicals: entry.supportCanonicals,
            isBlend: entry.isBlend,
          ),
        );
        added++;
        continue;
      }

      final current = updated[existingIndex];
      final next = current.copyWith(
        name: entry.name,
        inStock: true,
        catalogId: entry.id,
        canonicalName: entry.canonicalName,
        category: entry.category,
        supportCanonicals: entry.supportCanonicals,
        isBlend: entry.isBlend,
      );
      if (!current.inStock) {
        enabled++;
      }
      updated[existingIndex] = next;
    }

    await _repo.replaceAll(updated);
    _load();
    return ShelfBatchUpdateResult(added: added, enabled: enabled);
  }
}

final shelfListProvider =
    StateNotifierProvider<ShelfListNotifier, List<ShelfItem>>((ref) {
  final repo = ref.watch(shelfRepoProvider);
  return ShelfListNotifier(repo);
});
