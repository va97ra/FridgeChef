import '../../../core/utils/units.dart';
import 'detected_product_draft.dart';
import 'fridge_item.dart';
import 'product_catalog_entry.dart';
import 'product_search_suggestion.dart';

class AmountUnitParseResult {
  final double amount;
  final Unit unit;

  const AmountUnitParseResult({
    required this.amount,
    required this.unit,
  });
}

class CatalogMatchResult {
  final String productId;
  final String name;
  final double confidence;
  final Unit defaultUnit;
  final String matchedAlias;

  const CatalogMatchResult({
    required this.productId,
    required this.name,
    required this.confidence,
    required this.defaultUnit,
    required this.matchedAlias,
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
  final matches = findCatalogMatches(token, catalog, limit: 1);
  if (matches.isEmpty) {
    return null;
  }
  final best = matches.first;
  return CatalogMatchResult(
    productId: best.id,
    name: best.name,
    confidence: best.score,
    defaultUnit: best.defaultUnit,
    matchedAlias: best.matchedText,
  );
}

List<ProductSearchSuggestion> findCatalogMatches(
  String token,
  List<ProductCatalogEntry> catalog, {
  int limit = 5,
}) {
  final normalizedToken = normalizeProductToken(token);
  if (normalizedToken.isEmpty) {
    return const [];
  }

  final matches = <ProductSearchSuggestion>[];
  for (final entry in catalog) {
    final normalizedName = normalizeProductToken(entry.name);
    final aliases = <String>{
      normalizedName,
      ...entry.synonyms.map(normalizeProductToken),
    };

    double? bestScore;
    String? bestAlias;
    for (final alias in aliases) {
      if (alias.isEmpty) {
        continue;
      }
      final score = _scoreAlias(normalizedToken, alias);

      if (score == null) {
        continue;
      }
      if (bestScore == null || score > bestScore) {
        bestScore = score;
        bestAlias = alias;
      }
    }

    if (bestScore == null || bestAlias == null) {
      continue;
    }
    matches.add(
      ProductSearchSuggestion(
        id: entry.id,
        catalogId: entry.id,
        name: entry.name,
        matchedText: bestAlias,
        defaultUnit: entry.defaultUnit,
        source: ProductSuggestionSource.catalog,
        score: bestScore,
      ),
    );
  }

  matches.sort((a, b) {
    final scoreCompare = b.score.compareTo(a.score);
    if (scoreCompare != 0) {
      return scoreCompare;
    }
    return a.name.compareTo(b.name);
  });
  return matches.take(limit).toList();
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

double? _scoreAlias(String query, String alias) {
  if (query == alias) {
    return 0.99;
  }
  if (alias.startsWith(query)) {
    return 0.93;
  }
  if (query.startsWith(alias)) {
    return 0.89;
  }
  if (alias.contains(query)) {
    return 0.83;
  }
  if (query.contains(alias)) {
    return 0.8;
  }

  final distance = _levenshteinDistance(query, alias);
  final maxDistance = query.length <= 5 ? 1 : 2;
  if (distance > maxDistance) {
    return null;
  }
  return 0.72 - (distance * 0.08);
}

int _levenshteinDistance(String a, String b) {
  if (a == b) {
    return 0;
  }
  if (a.isEmpty) {
    return b.length;
  }
  if (b.isEmpty) {
    return a.length;
  }

  final previous = List<int>.generate(b.length + 1, (index) => index);
  final current = List<int>.filled(b.length + 1, 0);

  for (var i = 1; i <= a.length; i++) {
    current[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final substitutionCost =
          a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      current[j] = [
        current[j - 1] + 1,
        previous[j] + 1,
        previous[j - 1] + substitutionCost,
      ].reduce((value, element) => value < element ? value : element);
    }

    for (var j = 0; j < previous.length; j++) {
      previous[j] = current[j];
    }
  }

  return previous[b.length];
}
