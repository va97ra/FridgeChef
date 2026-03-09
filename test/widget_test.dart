import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/fridge/data/fridge_repo.dart';
import 'package:help_to_cook/features/fridge/domain/fridge_item.dart';
import 'package:help_to_cook/features/home/presentation/home_screen.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_match.dart';
import 'package:help_to_cook/features/recipes/presentation/providers.dart';
import 'package:help_to_cook/features/shelf/data/shelf_repo.dart';
import 'package:help_to_cook/features/shelf/domain/shelf_item.dart';

void main() {
  testWidgets('Home screen renders 3 main actions', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fridgeRepoProvider.overrideWithValue(_FakeFridgeRepo()),
          shelfRepoProvider.overrideWithValue(_FakeShelfRepo()),
          recipeMatchesProvider.overrideWith((ref) => const <RecipeMatch>[]),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Мой холодильник'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Открыть раздел Мой холодильник')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Полка'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Полка'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Открыть раздел Полка')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Помоги приготовить'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Помоги приготовить'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Открыть раздел Помоги приготовить')),
      findsOneWidget,
    );

    semantics.dispose();
  });
}

class _FakeFridgeRepo extends FridgeRepo {
  _FakeFridgeRepo() : super(boxName: 'test');

  @override
  List<FridgeItem> getAll() => const [
        FridgeItem(
          id: 'egg',
          name: 'Яйца',
          amount: 6,
          unit: Unit.pcs,
        ),
      ];
}

class _FakeShelfRepo extends ShelfRepo {
  _FakeShelfRepo() : super(boxName: 'test');

  @override
  List<ShelfItem> getAll() => const [
        ShelfItem(
          id: 'salt',
          name: 'Соль',
          inStock: true,
        ),
      ];
}
