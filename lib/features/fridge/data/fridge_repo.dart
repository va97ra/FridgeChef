import 'package:hive/hive.dart';
import '../domain/fridge_item.dart';
import 'fridge_hive_dto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final fridgeRepoProvider = Provider<FridgeRepo>((ref) {
  return FridgeRepo(boxName: 'fridgeBox');
});

class FridgeRepo {
  final String boxName;

  FridgeRepo({required this.boxName});

  Box<FridgeHiveDto> _getBox() {
    return Hive.box<FridgeHiveDto>(boxName);
  }

  List<FridgeItem> getAll() {
    final list = _getBox().values.map((dto) => dto.toDomain()).toList();
    // Сортировка по имени по умолчанию
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  Future<void> upsert(FridgeItem item) async {
    final dto = FridgeHiveDto.fromDomain(item);
    await _getBox().put(dto.id, dto);
  }

  Future<void> delete(String id) async {
    await _getBox().delete(id);
  }

  Future<void> clear() async {
    await _getBox().clear();
  }

  Future<void> replaceAll(List<FridgeItem> items) async {
    final box = _getBox();
    await box.clear();
    if (items.isEmpty) {
      return;
    }
    await box.putAll({
      for (final item in items) item.id: FridgeHiveDto.fromDomain(item),
    });
  }
}
