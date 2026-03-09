import '../../../core/utils/units.dart';

class UserProductMemoryEntry {
  final String key;
  final String name;
  final String? productId;
  final Unit lastUnit;
  final double? lastAmount;
  final int frequency;
  final DateTime lastUsedAt;

  const UserProductMemoryEntry({
    required this.key,
    required this.name,
    required this.productId,
    required this.lastUnit,
    required this.lastAmount,
    required this.frequency,
    required this.lastUsedAt,
  });

  UserProductMemoryEntry copyWith({
    String? key,
    String? name,
    String? productId,
    Unit? lastUnit,
    double? lastAmount,
    int? frequency,
    DateTime? lastUsedAt,
  }) {
    return UserProductMemoryEntry(
      key: key ?? this.key,
      name: name ?? this.name,
      productId: productId ?? this.productId,
      lastUnit: lastUnit ?? this.lastUnit,
      lastAmount: lastAmount ?? this.lastAmount,
      frequency: frequency ?? this.frequency,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  factory UserProductMemoryEntry.fromJson(Map<String, dynamic> json) {
    return UserProductMemoryEntry(
      key: json['key'] as String? ?? '',
      name: json['name'] as String? ?? '',
      productId: json['productId'] as String?,
      lastUnit: _parseUnit(json['lastUnit'] as String?) ?? Unit.pcs,
      lastAmount: (json['lastAmount'] as num?)?.toDouble(),
      frequency: (json['frequency'] as num?)?.toInt() ?? 1,
      lastUsedAt: DateTime.tryParse(json['lastUsedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'name': name,
      'productId': productId,
      'lastUnit': lastUnit.name,
      'lastAmount': lastAmount,
      'frequency': frequency,
      'lastUsedAt': lastUsedAt.toIso8601String(),
    };
  }

  static Unit? _parseUnit(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    for (final unit in Unit.values) {
      if (unit.name == value) {
        return unit;
      }
    }
    return null;
  }
}
