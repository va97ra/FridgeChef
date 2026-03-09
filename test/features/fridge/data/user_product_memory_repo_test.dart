import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/fridge/data/user_product_memory_repo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('recordProduct stores first product in empty memory', () async {
    const repo = UserProductMemoryRepo();

    await repo.recordProduct(
      name: 'Яйца',
      unit: Unit.pcs,
      amount: 6,
      productId: 'eggs',
    );

    final items = await repo.loadAll();

    expect(items, hasLength(1));
    expect(items.single.key, 'catalog:eggs');
    expect(items.single.name, 'Яйца');
    expect(items.single.lastUnit, Unit.pcs);
    expect(items.single.lastAmount, 6);
    expect(items.single.frequency, 1);
  });
}
