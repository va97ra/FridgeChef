import 'package:hive/hive.dart';
import '../../domain/fridge_item.dart';
import '../../../core/utils/units.dart';

part 'fridge_hive_dto.g.dart';

@HiveType(typeId: 0)
class FridgeHiveDto extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String unitStr;

  @HiveField(4)
  final DateTime? expiresAt;

  @HiveField(5)
  final int? calories;

  FridgeHiveDto({
    required this.id,
    required this.name,
    required this.amount,
    required this.unitStr,
    this.expiresAt,
    this.calories,
  });

  factory FridgeHiveDto.fromDomain(FridgeItem item) {
    return FridgeHiveDto(
      id: item.id,
      name: item.name,
      amount: item.amount,
      unitStr: item.unit.name,
      expiresAt: item.expiresAt,
      calories: item.calories,
    );
  }

  FridgeItem toDomain() {
    return FridgeItem(
      id: id,
      name: name,
      amount: amount,
      unit: Unit.values.firstWhere((e) => e.name == unitStr, orElse: () => Unit.pcs),
      expiresAt: expiresAt,
      calories: calories,
    );
  }
}
