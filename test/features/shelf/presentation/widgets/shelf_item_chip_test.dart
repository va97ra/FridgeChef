import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/theme/app_theme.dart';
import 'package:help_to_cook/features/shelf/domain/shelf_item.dart';
import 'package:help_to_cook/features/shelf/presentation/widgets/shelf_item_chip.dart';

void main() {
  testWidgets('shows pantry category badge on shelf chip', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Material(
          child: ShelfItemChip(
            item: const ShelfItem(
              id: '1',
              name: 'Соевый соус',
              inStock: true,
              category: 'sauce',
              canonicalName: 'соевый соус',
              supportCanonicals: ['умами акцент'],
            ),
            onToggle: () {},
            onLongPress: () {},
          ),
        ),
      ),
    );

    expect(find.text('Соевый соус'), findsOneWidget);
    expect(find.text('Соусы'), findsOneWidget);
    expect(find.text('Есть дома'), findsOneWidget);
  });
}
