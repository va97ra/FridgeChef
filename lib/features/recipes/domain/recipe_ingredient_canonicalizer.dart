import '../../fridge/domain/photo_import_utils.dart';
import '../../fridge/domain/product_catalog_entry.dart';
import 'ingredient_knowledge.dart';

class RecipeIngredientCanonicalizer {
  final List<ProductCatalogEntry> catalog;
  final Map<String, String> _aliasToCanonical = {};

  RecipeIngredientCanonicalizer(this.catalog) {
    for (final entry in catalog) {
      final canonical = normalizeIngredientText(entry.canonicalName);
      if (canonical.isEmpty) {
        continue;
      }

      final aliases = <String>{
        normalizeIngredientText(entry.name),
        normalizeIngredientText(entry.canonicalName),
        ...entry.synonyms.map(normalizeIngredientText),
      };
      for (final alias in aliases) {
        if (alias.isEmpty) {
          continue;
        }
        _aliasToCanonical[alias] = canonical;
      }
    }
  }

  String canonicalize(
    String raw, {
    Iterable<String> extraKnownNames = const [],
  }) {
    final normalized = normalizeIngredientText(raw);
    if (normalized.isEmpty) {
      return normalized;
    }

    final exact = _aliasToCanonical[normalized];
    if (exact != null) {
      return exact;
    }

    final extraAliases = extraKnownNames
        .map(normalizeIngredientText)
        .where((value) => value.isNotEmpty)
        .toSet();
    if (extraAliases.contains(normalized)) {
      return normalized;
    }

    final containsCandidate = _bestContainsMatch(normalized);
    if (containsCandidate != null) {
      return containsCandidate;
    }

    final fuzzy = findBestCatalogMatch(normalized, catalog);
    if (fuzzy != null && fuzzy.confidence >= 0.72) {
      return _aliasToCanonical[normalizeIngredientText(fuzzy.name)] ??
          normalizeIngredientText(fuzzy.name);
    }

    String? bestExtra;
    for (final extra in extraAliases) {
      if (normalized.contains(extra) || extra.contains(normalized)) {
        if (bestExtra == null || extra.length > bestExtra.length) {
          bestExtra = extra;
        }
      }
    }

    return bestExtra ?? normalized;
  }

  String? _bestContainsMatch(String normalized) {
    String? candidate;
    var candidateLength = -1;
    for (final entry in _aliasToCanonical.entries) {
      final alias = entry.key;
      if (normalized.contains(alias) || alias.contains(normalized)) {
        if (alias.length > candidateLength) {
          candidate = entry.value;
          candidateLength = alias.length;
        }
      }
    }
    return candidate;
  }
}
