import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/theme/app_theme.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/fridge/data/fridge_repo.dart';
import 'package:help_to_cook/features/fridge/domain/fridge_item.dart';
import 'package:help_to_cook/features/fridge/presentation/fridge_list_screen.dart';

void main() {
  testWidgets('shows photo source bottom sheet', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fridgeRepoProvider.overrideWithValue(_FakeFridgeRepo()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const FridgeListScreen(),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.camera_alt_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Добавить по фото'), findsOneWidget);
    expect(find.text('Сделать фото'), findsOneWidget);
    expect(find.text('Выбрать из галереи'), findsOneWidget);
  });

  testWidgets('exposes item actions through semantics and delete button works',
      (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fridgeRepoProvider.overrideWithValue(_FakeFridgeRepo()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const FridgeListScreen(),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel(RegExp('Открыть продукт Яйца')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Удалить продукт Яйца'),
      findsOneWidget,
    );

    await tester.tap(find.bySemanticsLabel('Удалить продукт Яйца'));
    await tester.pumpAndSettle();

    expect(find.text('Холодильник пока пуст'), findsOneWidget);

    semantics.dispose();
  });
}

class _FakeFridgeRepo extends FridgeRepo {
  final Map<String, FridgeItem> _items = {
    'f1': const FridgeItem(
      id: 'f1',
      name: 'Яйца',
      amount: 4,
      unit: Unit.pcs,
    ),
  };

  _FakeFridgeRepo() : super(boxName: 'test');

  @override
  List<FridgeItem> getAll() => _items.values.toList();

  @override
  Future<void> upsert(FridgeItem item) async {
    _items[item.id] = item;
  }

  @override
  Future<void> delete(String id) async {
    _items.remove(id);
  }
}
