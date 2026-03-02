import 'package:hive/hive.dart';
import '../domain/shelf_item.dart';
import 'shelf_hive_dto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  Future<void> upsert(ShelfItem item) async {
    final dto = ShelfHiveDto.fromDomain(item);
    await _getBox().put(dto.id, dto);
  }

  Future<void> delete(String id) async {
    await _getBox().delete(id);
  }
}
