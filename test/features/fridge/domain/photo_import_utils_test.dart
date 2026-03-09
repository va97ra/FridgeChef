import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/fridge/domain/detected_product_draft.dart';
import 'package:help_to_cook/features/fridge/domain/fridge_item.dart';
import 'package:help_to_cook/features/fridge/domain/photo_import_utils.dart';
import 'package:help_to_cook/features/fridge/domain/product_catalog_entry.dart';

void main() {
  test('extracts amount and unit from OCR text', () {
    final parsed = tryExtractAmountUnit('Молоко 1,5 л');
    expect(parsed, isNotNull);
    expect(parsed!.amount, 1.5);
    expect(parsed.unit, Unit.l);
  });

  test('finds best catalog match by contains', () {
    final catalog = [
      const ProductCatalogEntry(
        id: 'eggs',
        name: 'Яйца',
        synonyms: ['яйцо', 'яйца'],
      ),
      const ProductCatalogEntry(
        id: 'milk',
        name: 'Молоко',
        synonyms: ['молоко'],
      ),
    ];
    final match = findBestCatalogMatch('десяток яйца', catalog);
    expect(match, isNotNull);
    expect(match!.name, 'Яйца');
  });

  test('finds transliterated colloquial ingredient aliases in catalog', () {
    final catalog = [
      const ProductCatalogEntry(
        id: 'glass_noodles',
        name: 'Фунчоза',
        canonicalName: 'Макароны',
        synonyms: ['фунчоза', 'фунчеза', 'фанзю', 'funchoza', 'fanju'],
        defaultUnit: Unit.g,
      ),
      const ProductCatalogEntry(
        id: 'soy_sauce',
        name: 'Соевый соус',
        synonyms: ['соевый соус', 'соус соевый', 'soy sauce'],
        defaultUnit: Unit.ml,
      ),
    ];

    final funchozaMatch = findBestCatalogMatch('фанзю', catalog);
    expect(funchozaMatch, isNotNull);
    expect(funchozaMatch!.name, 'Фунчоза');

    final soySauceMatch = findBestCatalogMatch('соус соевый', catalog);
    expect(soySauceMatch, isNotNull);
    expect(soySauceMatch!.name, 'Соевый соус');
  });

  test('suggests merge target for compatible duplicate names', () {
    final draft = const DetectedProductDraft(
      id: 'd1',
      name: 'Молоко',
      amount: 1,
      unit: Unit.l,
      confidence: 0.8,
      rawTokens: ['молоко'],
      source: DetectionSource.local,
    );
    final items = [
      const FridgeItem(id: 'f1', name: 'молоко', amount: 0.5, unit: Unit.l),
      const FridgeItem(id: 'f2', name: 'яйца', amount: 10, unit: Unit.pcs),
    ];

    final targetId = suggestMergeTargetId(draft: draft, fridgeItems: items);
    expect(targetId, 'f1');
  });
}
