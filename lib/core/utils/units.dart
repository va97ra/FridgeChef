import 'package:flutter/material.dart';

enum Unit { g, kg, ml, l, pcs }

extension UnitExtension on Unit {
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
}
