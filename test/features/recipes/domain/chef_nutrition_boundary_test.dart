import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chef decision logic stays isolated from nutrition fields', () {
    const chefDecisionFiles = [
      'lib/features/recipes/domain/offline_chef_engine.dart',
      'lib/features/recipes/domain/chef_rules.dart',
      'lib/features/recipes/domain/chef_dish_validator.dart',
    ];

    for (final path in chefDecisionFiles) {
      final text = File(path).readAsStringSync().toLowerCase();
      expect(
        text.contains('nutrition'),
        isFalse,
        reason: 'Decision logic should not depend on nutrition fields: $path',
      );
      expect(
        text.contains('calor'),
        isFalse,
        reason: 'Decision logic should not depend on calories: $path',
      );
    }
  });

  test('nutrition estimator remains available for display layer', () {
    final estimatorText = File(
      'lib/features/recipes/domain/recipe_nutrition_estimator.dart',
    ).readAsStringSync().toLowerCase();

    expect(estimatorText.contains('nutrition'), isTrue);
  });
}
