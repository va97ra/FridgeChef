import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/utils/units.dart';

void main() {
  group('UnitConverter', () {
    test('converts mass and volume through canonical unit', () {
      expect(
        UnitConverter.convert(amount: 1, from: Unit.kg, to: Unit.g),
        1000,
      );
      expect(
        UnitConverter.convert(amount: 750, from: Unit.ml, to: Unit.l),
        0.75,
      );
    });

    test('returns null for incompatible unit families', () {
      expect(
        UnitConverter.convert(amount: 10, from: Unit.g, to: Unit.pcs),
        isNull,
      );
    });
  });
}
