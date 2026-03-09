import 'package:flutter_test/flutter_test.dart';

import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/fridge/data/fridge_repo.dart';
import 'package:help_to_cook/features/fridge/data/user_product_memory_repo.dart';
import 'package:help_to_cook/features/fridge/domain/fridge_item.dart';
import 'package:help_to_cook/features/fridge/presentation/providers.dart';

class _FakeFridgeRepo extends FridgeRepo {
  _FakeFridgeRepo() : super(boxName: 'test');

  final List<FridgeItem> items = [];

  @override
  List<FridgeItem> getAll() => List<FridgeItem>.from(items);

  @override
  Future<void> upsert(FridgeItem item) async {
    items.removeWhere((existing) => existing.id == item.id);
    items.add(item);
  }

  @override
  Future<void> delete(String id) async {
    items.removeWhere((existing) => existing.id == id);
  }
}

class _ThrowingUserProductMemoryRepo extends UserProductMemoryRepo {
  @override
  Future<void> recordProduct({
    required String name,
    required Unit unit,
    required double amount,
    String? productId,
  }) {
    throw StateError('memory unavailable');
  }
}

void main() {
  test('addItem still updates fridge state when memory recording fails', () async {
    final repo = _FakeFridgeRepo();
    final notifier = FridgeListNotifier(repo, _ThrowingUserProductMemoryRepo());
    final item = FridgeItem(
      id: 'egg-1',
      name: 'Яйца',
      amount: 6,
      unit: Unit.pcs,
    );

    await notifier.addItem(item);

    expect(repo.items, hasLength(1));
    expect(repo.items.single.name, 'Яйца');
    expect(notifier.state, hasLength(1));
    expect(notifier.state.single.amount, 6);
  });
}
