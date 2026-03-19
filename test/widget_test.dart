import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/theme/app_theme.dart';
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
    final homeScroll = find.descendant(
      of: find.byType(ListView),
      matching: find.byType(Scrollable),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fridgeRepoProvider.overrideWithValue(_FakeFridgeRepo()),
          shelfRepoProvider.overrideWithValue(_FakeShelfRepo()),
          recipeMatchesProvider.overrideWith((ref) => const <RecipeMatch>[]),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fridgeAction =
        find.bySemanticsLabel(RegExp('Открыть раздел Мой холодильник'));
    final shelfAction = find.bySemanticsLabel(RegExp('Открыть раздел Полка'));
    final cookAction =
        find.bySemanticsLabel(RegExp('Открыть раздел Помоги приготовить'));

    await tester.scrollUntilVisible(
      fridgeAction,
      250,
      scrollable: homeScroll,
    );
    await tester.pumpAndSettle();
    expect(find.text('Мой холодильник', skipOffstage: false), findsWidgets);
    expect(fridgeAction, findsOneWidget);
    await tester.scrollUntilVisible(
      shelfAction,
      250,
      scrollable: homeScroll,
    );
    await tester.pumpAndSettle();
    expect(find.text('Полка', skipOffstage: false), findsWidgets);
    expect(shelfAction, findsOneWidget);
    await tester.scrollUntilVisible(
      cookAction,
      250,
      scrollable: homeScroll,
    );
    await tester.pumpAndSettle();
    expect(find.text('Помоги приготовить', skipOffstage: false), findsWidgets);
    expect(cookAction, findsOneWidget);

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
