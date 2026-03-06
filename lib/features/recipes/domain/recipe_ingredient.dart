import '../../../core/utils/units.dart';

class RecipeIngredient {
  final String name;
  final double amount;
  final Unit unit;
  final bool required;

  const RecipeIngredient({
    required this.name,
    required this.amount,
    required this.unit,
    this.required = true,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      unit: Unit.values
          .firstWhere((e) => e.name == json['unit'], orElse: () => Unit.pcs),
      required: json['required'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'unit': unit.name,
      'required': required,
    };
  }
}
