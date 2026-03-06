import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/fridge/data/fridge_repo.dart';
import 'package:help_to_cook/features/fridge/domain/detected_product_draft.dart';
import 'package:help_to_cook/features/fridge/domain/fridge_item.dart';
import 'package:help_to_cook/features/fridge/domain/photo_import_result.dart';
import 'package:help_to_cook/features/fridge/presentation/fridge_photo_review_screen.dart';

void main() {
  testWidgets('shows default merge option for duplicates', (tester) async {
    final result = PhotoImportResult(
      imagePath: '/tmp/test.jpg',
      drafts: const [
        DetectedProductDraft(
          id: 'd1',
          name: 'Молоко',
          amount: 1,
          unit: Unit.l,
          confidence: 0.8,
          rawTokens: ['молоко'],
          source: DetectionSource.local,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fridgeRepoProvider.overrideWithValue(_FakeFridgeRepo()),
        ],
        child: MaterialApp(
          home: FridgePhotoReviewScreen(result: result),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Объединить с "Молоко"'), findsOneWidget);
  });
}

class _FakeFridgeRepo extends FridgeRepo {
  final Map<String, FridgeItem> _items = {
    'f1': const FridgeItem(
      id: 'f1',
      name: 'Молоко',
      amount: 0.5,
      unit: Unit.l,
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
