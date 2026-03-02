import 'package:hive/hive.dart';
import '../domain/shelf_item.dart';

part 'shelf_hive_dto.g.dart';

@HiveType(typeId: 1)
class ShelfHiveDto extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final bool inStock;

  ShelfHiveDto({
    required this.id,
    required this.name,
    required this.inStock,
  });

  factory ShelfHiveDto.fromDomain(ShelfItem item) {
    return ShelfHiveDto(
      id: item.id,
      name: item.name,
      inStock: item.inStock,
    );
  }

  ShelfItem toDomain() {
    return ShelfItem(
      id: id,
      name: name,
      inStock: inStock,
    );
  }
}
