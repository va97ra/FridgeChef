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

  factory FridgeItem.fromJson(Map<String, dynamic> json) {
    return FridgeItem(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      unit: UnitExtension.fromStorage(json['unit'] as String? ?? 'g'),
      expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),
      calories: json['calories'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'unit': unit.storageValue,
      'expiresAt': expiresAt?.toIso8601String(),
      'calories': calories,
    };
  }

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
