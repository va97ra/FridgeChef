import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/app/app.dart';

void main() {
  testWidgets('Home screen renders 3 main actions', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Мой холодильник'), findsOneWidget);
    expect(find.text('Полка'), findsOneWidget);
    expect(find.text('Помоги приготовить'), findsAtLeastNWidgets(1));
  });
}
