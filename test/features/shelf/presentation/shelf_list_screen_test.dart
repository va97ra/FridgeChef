import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/theme/app_theme.dart';
import 'package:help_to_cook/features/shelf/data/shelf_repo.dart';
import 'package:help_to_cook/features/shelf/domain/shelf_item.dart';
import 'package:help_to_cook/features/shelf/presentation/shelf_list_screen.dart';

void main() {
  testWidgets('groups shelf items by pantry category', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shelfRepoProvider.overrideWithValue(
            _MemoryShelfRepo([
              const ShelfItem(
                id: '1',
                name: 'Соль',
                inStock: true,
                category: 'basic',
                canonicalName: 'соль',
              ),
              const ShelfItem(
                id: '2',
                name: 'Соевый соус',
                inStock: true,
                category: 'sauce',
                canonicalName: 'соевый соус',
              ),
              const ShelfItem(
                id: '3',
                name: 'Карри',
                inStock: true,
                category: 'blend',
                canonicalName: 'карри',
                isBlend: true,
              ),
            ]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ShelfListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('База'), findsWidgets);
    expect(find.text('Соусы'), findsWidgets);
    expect(find.text('Смеси'), findsWidgets);
    expect(find.text('Соль'), findsOneWidget);
    expect(find.text('Соевый соус'), findsOneWidget);
    expect(find.text('Карри'), findsOneWidget);
  });

  testWidgets('filters shelf items by search query and category',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shelfRepoProvider.overrideWithValue(
            _MemoryShelfRepo([
              const ShelfItem(
                id: '1',
                name: 'Соль',
                inStock: true,
                category: 'basic',
                canonicalName: 'соль',
              ),
              const ShelfItem(
                id: '2',
                name: 'Соевый соус',
                inStock: true,
                category: 'sauce',
                canonicalName: 'соевый соус',
              ),
              const ShelfItem(
                id: '3',
                name: 'Карри',
                inStock: true,
                category: 'blend',
                canonicalName: 'карри',
                isBlend: true,
              ),
            ]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ShelfListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'соев');
    await tester.pumpAndSettle();

    expect(find.text('Соевый соус'), findsOneWidget);
    expect(find.text('Соль'), findsNothing);
    expect(find.text('Карри'), findsNothing);

    await tester.enterText(find.byType(TextFormField), '');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('shelf-filter-blend')));
    await tester.pumpAndSettle();

    expect(find.text('Карри'), findsOneWidget);
    expect(find.text('Соевый соус'), findsNothing);
    expect(find.text('Соль'), findsNothing);
  });

  testWidgets('filters shelf items by availability state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shelfRepoProvider.overrideWithValue(
            _MemoryShelfRepo([
              const ShelfItem(
                id: '1',
                name: 'Соль',
                inStock: true,
                category: 'basic',
                canonicalName: 'соль',
              ),
              const ShelfItem(
                id: '2',
                name: 'Горчица',
                inStock: false,
                category: 'sauce',
                canonicalName: 'горчица',
              ),
            ]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ShelfListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Быстрые наборы'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('shelf-availability-in')));
    await tester.pumpAndSettle();

    expect(find.text('Соль'), findsOneWidget);
    expect(find.text('Горчица'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('shelf-availability-out')));
    await tester.pumpAndSettle();

    expect(find.text('Соль'), findsNothing);
    expect(find.text('Горчица'), findsOneWidget);
  });
}

class _MemoryShelfRepo extends ShelfRepo {
  final List<ShelfItem> _items;

  _MemoryShelfRepo(List<ShelfItem> items)
      : _items = List<ShelfItem>.from(items),
        super(boxName: 'ignored');

  @override
  List<ShelfItem> getAll() => List<ShelfItem>.from(_items);
}
