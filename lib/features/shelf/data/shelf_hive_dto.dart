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

  @HiveField(3)
  final String? catalogId;

  @HiveField(4)
  final String canonicalName;

  @HiveField(5)
  final String category;

  @HiveField(6)
  final List<String> supportCanonicals;

  @HiveField(7)
  final bool isBlend;

  ShelfHiveDto({
    required this.id,
    required this.name,
    required this.inStock,
    this.catalogId,
    required this.canonicalName,
    required this.category,
    this.supportCanonicals = const [],
    this.isBlend = false,
  });

  factory ShelfHiveDto.fromDomain(ShelfItem item) {
    return ShelfHiveDto(
      id: item.id,
      name: item.name,
      inStock: item.inStock,
      catalogId: item.catalogId,
      canonicalName: item.canonicalName,
      category: item.category,
      supportCanonicals: item.supportCanonicals,
      isBlend: item.isBlend,
    );
  }

  ShelfItem toDomain() {
    return ShelfItem(
      id: id,
      name: name,
      inStock: inStock,
      catalogId: catalogId,
      canonicalName: canonicalName,
      category: category,
      supportCanonicals: supportCanonicals,
      isBlend: isBlend,
    );
  }
}
