import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/features/shelf/data/shelf_repo.dart';
import 'package:help_to_cook/features/shelf/domain/pantry_catalog_entry.dart';
import 'package:help_to_cook/features/shelf/domain/shelf_item.dart';
import 'package:help_to_cook/features/shelf/presentation/providers.dart';

void main() {
  test('quick pantry batch adds new entries and enables existing ones',
      () async {
    final repo = _MemoryShelfRepo([
      const ShelfItem(
        id: 'oil',
        name: 'Подсолнечное масло',
        inStock: false,
        catalogId: 'oil',
        canonicalName: 'масло',
        category: 'oil',
        supportCanonicals: ['жирная связка'],
      ),
    ]);
    final notifier = ShelfListNotifier(repo);

    final result = await notifier.addOrEnablePantryEntries([
      const PantryCatalogEntry(
        id: 'salt',
        name: 'Соль',
        canonicalName: 'соль',
        aliases: ['соль'],
        category: 'basic',
      ),
      const PantryCatalogEntry(
        id: 'oil',
        name: 'Подсолнечное масло',
        canonicalName: 'масло',
        aliases: ['масло'],
        category: 'oil',
        supportCanonicals: ['жирная связка'],
      ),
    ]);

    expect(result.added, 1);
    expect(result.enabled, 1);
    expect(notifier.state, hasLength(2));
    expect(
      notifier.state.where((item) => item.catalogId == 'oil').single.inStock,
      isTrue,
    );
    expect(
      notifier.state.where((item) => item.catalogId == 'salt'),
      isNotEmpty,
    );
  });
}

class _MemoryShelfRepo extends ShelfRepo {
  List<ShelfItem> _items;

  _MemoryShelfRepo(List<ShelfItem> items)
      : _items = List<ShelfItem>.from(items),
        super(boxName: 'ignored');

  @override
  List<ShelfItem> getAll() => List<ShelfItem>.from(_items);

  @override
  Future<void> upsert(ShelfItem item) async {
    final index = _items.indexWhere((entry) => entry.id == item.id);
    if (index == -1) {
      _items.add(item);
    } else {
      _items[index] = item;
    }
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> clear() async {
    _items = [];
  }

  @override
  Future<void> replaceAll(List<ShelfItem> items) async {
    _items = List<ShelfItem>.from(items);
  }
}
