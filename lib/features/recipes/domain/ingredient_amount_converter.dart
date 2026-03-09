import '../../../core/utils/units.dart';

double? convertIngredientAmount({
  required String canonical,
  required double amount,
  required Unit from,
  required Unit to,
}) {
  final direct = UnitConverter.convert(amount: amount, from: from, to: to);
  if (direct != null) {
    return direct;
  }

  final gramsPerPiece = _approxMassPerPiece[canonical];
  if (gramsPerPiece == null) {
    return null;
  }

  if (from == Unit.pcs && to == Unit.g) {
    return amount * gramsPerPiece;
  }
  if (from == Unit.g && to == Unit.pcs) {
    return amount / gramsPerPiece;
  }
  if (from == Unit.pcs && to == Unit.kg) {
    return (amount * gramsPerPiece) / 1000.0;
  }
  if (from == Unit.kg && to == Unit.pcs) {
    return (amount * 1000.0) / gramsPerPiece;
  }

  return null;
}

const Map<String, double> _approxMassPerPiece = {
  'яблоко': 150,
  'банан': 120,
  'апельсин': 160,
  'лимон': 90,
  'помидор': 130,
  'огурец': 120,
  'лук': 90,
  'картофель': 150,
  'морковь': 80,
  'перец сладкий': 140,
  'кабачок': 250,
};
