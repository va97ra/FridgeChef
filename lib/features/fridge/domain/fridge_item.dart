import '../../../core/utils/units.dart';

class FridgeItem {
  final String id;
  final String name;
  final double amount;
  final Unit unit;
  final DateTime? expiresAt;
  final int? calories;

  const FridgeItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.unit,
    this.expiresAt,
    this.calories,
  });

  FridgeItem copyWith({
    String? id,
    String? name,
    double? amount,
    Unit? unit,
    DateTime? expiresAt,
    int? calories,
  }) {
    return FridgeItem(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      expiresAt: expiresAt ?? this.expiresAt,
      calories: calories ?? this.calories,
    );
  }
}
