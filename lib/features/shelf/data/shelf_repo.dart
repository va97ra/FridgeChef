import 'package:hive/hive.dart';
import '../domain/shelf_item.dart';
import 'shelf_hive_dto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const Map<String, int> _categoryOrder = {
  'basic': 0,
  'spice': 1,
  'herb': 2,
  'oil': 3,
  'sauce': 4,
  'dairy': 5,
  'blend': 6,
  'other': 7,
};

final shelfRepoProvider = Provider<ShelfRepo>((ref) {
  return ShelfRepo(boxName: 'shelfBox');
});

class ShelfRepo {
  final String boxName;

  ShelfRepo({required this.boxName});

  Box<ShelfHiveDto> _getBox() {
    return Hive.box<ShelfHiveDto>(boxName);
  }

  List<ShelfItem> getAll() {
    final list = _getBox().values.map((dto) => dto.toDomain()).toList();
    list.sort((a, b) {
      if (a.inStock != b.inStock) {
        return a.inStock ? -1 : 1;
      }
      final byCategory = (_categoryOrder[a.category] ?? 99)
          .compareTo(_categoryOrder[b.category] ?? 99);
      if (byCategory != 0) {
        return byCategory;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  Future<void> upsert(ShelfItem item) async {
    final dto = ShelfHiveDto.fromDomain(item);
    await _getBox().put(dto.id, dto);
  }

  Future<void> delete(String id) async {
    await _getBox().delete(id);
  }

  Future<void> clear() async {
    await _getBox().clear();
  }

  Future<void> replaceAll(List<ShelfItem> items) async {
    final box = _getBox();
    await box.clear();
    if (items.isEmpty) {
      return;
    }
    await box.putAll({
      for (final item in items) item.id: ShelfHiveDto.fromDomain(item),
    });
  }
}
