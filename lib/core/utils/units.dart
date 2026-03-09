enum Unit { g, kg, ml, l, pcs }

extension UnitExtension on Unit {
  String get storageValue => name;

  UnitFamily get family {
    switch (this) {
      case Unit.g:
      case Unit.kg:
        return UnitFamily.mass;
      case Unit.ml:
      case Unit.l:
        return UnitFamily.volume;
      case Unit.pcs:
        return UnitFamily.piece;
    }
  }

  String get label {
    switch (this) {
      case Unit.g:
        return 'г';
      case Unit.kg:
        return 'кг';
      case Unit.ml:
        return 'мл';
      case Unit.l:
        return 'л';
      case Unit.pcs:
        return 'шт';
    }
  }

  static Unit fromStorage(String raw) {
    return Unit.values.firstWhere(
      (unit) => unit.name == raw,
      orElse: () => Unit.g,
    );
  }
}

enum UnitFamily { mass, volume, piece }

class UnitConverter {
  static bool areCompatible(Unit from, Unit to) => from.family == to.family;

  static double? convert({
    required double amount,
    required Unit from,
    required Unit to,
  }) {
    if (!areCompatible(from, to)) {
      return null;
    }

    if (from == to) {
      return amount;
    }

    final canonicalAmount = _toCanonical(amount: amount, unit: from);
    return _fromCanonical(amount: canonicalAmount, unit: to);
  }

  static double _toCanonical({required double amount, required Unit unit}) {
    switch (unit) {
      case Unit.g:
      case Unit.ml:
      case Unit.pcs:
        return amount;
      case Unit.kg:
      case Unit.l:
        return amount * 1000.0;
    }
  }

  static double _fromCanonical({required double amount, required Unit unit}) {
    switch (unit) {
      case Unit.g:
      case Unit.ml:
      case Unit.pcs:
        return amount;
      case Unit.kg:
      case Unit.l:
        return amount / 1000.0;
    }
  }
}
