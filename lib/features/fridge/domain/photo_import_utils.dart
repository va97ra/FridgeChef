import '../../../core/utils/units.dart';
import 'detected_product_draft.dart';
import 'fridge_item.dart';
import 'product_catalog_entry.dart';

class AmountUnitParseResult {
  final double amount;
  final Unit unit;

  const AmountUnitParseResult({
    required this.amount,
    required this.unit,
  });
}

class CatalogMatchResult {
  final String name;
  final double confidence;

  const CatalogMatchResult({
    required this.name,
    required this.confidence,
  });
}

String normalizeProductToken(String value) {
  return value
      .toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll(RegExp(r'[^a-zA-Zа-яА-Я0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

AmountUnitParseResult? tryExtractAmountUnit(String input) {
  final normalized = input
      .toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll(RegExp(r'[^a-zA-Zа-яА-Я0-9,.\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final match = RegExp(
    r'(\d+(?:[.,]\d+)?)\s*(кг|килограмм|г|гр|грамм|мл|миллилитр|л|литр|шт|штук|штуки)',
  ).firstMatch(normalized);
  if (match == null) {
    return null;
  }

  final amount = double.tryParse(match.group(1)!.replaceAll(',', '.'));
  if (amount == null || amount <= 0) {
    return null;
  }

  final unitRaw = match.group(2)!;
  if (unitRaw.startsWith('кг')) {
    return AmountUnitParseResult(amount: amount, unit: Unit.kg);
  }
  if (unitRaw.startsWith('г')) {
    return AmountUnitParseResult(amount: amount, unit: Unit.g);
  }
  if (unitRaw.startsWith('мл')) {
    return AmountUnitParseResult(amount: amount, unit: Unit.ml);
  }
  if (unitRaw == 'л' || unitRaw.startsWith('лит')) {
    return AmountUnitParseResult(amount: amount, unit: Unit.l);
  }
  return AmountUnitParseResult(amount: amount, unit: Unit.pcs);
}

CatalogMatchResult? findBestCatalogMatch(
  String token,
  List<ProductCatalogEntry> catalog,
) {
  final normalizedToken = normalizeProductToken(token);
  if (normalizedToken.isEmpty) {
    return null;
  }

  CatalogMatchResult? best;
  for (final entry in catalog) {
    final normalizedName = normalizeProductToken(entry.name);
    final aliases = <String>{
      normalizedName,
      ...entry.synonyms.map(normalizeProductToken),
    };

    for (final alias in aliases) {
      if (alias.isEmpty) {
        continue;
      }
      double? score;
      if (alias == normalizedToken) {
        score = 0.98;
      } else if (normalizedToken.contains(alias)) {
        score = 0.88;
      } else if (alias.contains(normalizedToken)) {
        score = 0.78;
      }

      if (score == null) {
        continue;
      }

      if (best == null || score > best.confidence) {
        best = CatalogMatchResult(name: entry.name, confidence: score);
      }
    }
  }

  return best;
}

String? suggestMergeTargetId({
  required DetectedProductDraft draft,
  required List<FridgeItem> fridgeItems,
}) {
  final draftName = normalizeProductToken(draft.name);
  if (draftName.isEmpty) {
    return null;
  }

  FridgeItem? exact;
  FridgeItem? contains;
  for (final item in fridgeItems) {
    if (!UnitConverter.areCompatible(item.unit, draft.unit)) {
      continue;
    }
    final itemName = normalizeProductToken(item.name);
    if (itemName == draftName) {
      exact = item;
      break;
    }
    if (itemName.contains(draftName) || draftName.contains(itemName)) {
      contains ??= item;
    }
  }

  return exact?.id ?? contains?.id;
}
