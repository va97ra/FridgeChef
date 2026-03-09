import '../../fridge/domain/photo_import_utils.dart';
import '../../fridge/domain/product_catalog_entry.dart';
import 'ingredient_knowledge.dart';

class RecipeIngredientCanonicalizer {
  final List<ProductCatalogEntry> catalog;
  final Map<String, String> _aliasToCanonical = {};
  final Map<String, String> _relaxedAliasToCanonical = {};

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
        _indexAlias(alias, canonical);
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
    final relaxedNormalized = stripIngredientDescriptors(normalized);

    final exact = _aliasToCanonical[normalized];
    if (exact != null) {
      return exact;
    }
    final relaxedExact = _relaxedAliasToCanonical[relaxedNormalized] ??
        _aliasToCanonical[relaxedNormalized];
    if (relaxedExact != null) {
      return relaxedExact;
    }

    final extraAliases = extraKnownNames
        .map(normalizeIngredientText)
        .where((value) => value.isNotEmpty)
        .toSet();
    if (extraAliases.contains(normalized)) {
      return normalized;
    }
    final relaxedExtraAliases =
        extraAliases.map(stripIngredientDescriptors).toSet();
    if (relaxedExtraAliases.contains(relaxedNormalized)) {
      return relaxedNormalized;
    }

    final containsCandidate = _bestContainsMatch(normalized);
    if (containsCandidate != null) {
      return containsCandidate;
    }
    if (relaxedNormalized != normalized) {
      final relaxedContainsCandidate = _bestContainsMatch(
        relaxedNormalized,
        aliases: _relaxedAliasToCanonical,
      );
      if (relaxedContainsCandidate != null) {
        return relaxedContainsCandidate;
      }
    }

    final fuzzy = findBestCatalogMatch(normalized, catalog);
    if (fuzzy != null && fuzzy.confidence >= 0.72) {
      return _aliasToCanonical[normalizeIngredientText(fuzzy.name)] ??
          normalizeIngredientText(fuzzy.name);
    }
    if (relaxedNormalized != normalized) {
      final relaxedFuzzy = findBestCatalogMatch(relaxedNormalized, catalog);
      if (relaxedFuzzy != null && relaxedFuzzy.confidence >= 0.72) {
        return _aliasToCanonical[normalizeIngredientText(relaxedFuzzy.name)] ??
            normalizeIngredientText(relaxedFuzzy.name);
      }
    }

    String? bestExtra;
    for (final extra in extraAliases) {
      if (normalized.contains(extra) || extra.contains(normalized)) {
        if (bestExtra == null || extra.length > bestExtra.length) {
          bestExtra = extra;
        }
      }
    }
    if (bestExtra == null) {
      for (final extra in relaxedExtraAliases) {
        if (relaxedNormalized.contains(extra) ||
            extra.contains(relaxedNormalized)) {
          if (bestExtra == null || extra.length > bestExtra.length) {
            bestExtra = extra;
          }
        }
      }
    }

    return bestExtra ?? relaxedNormalized;
  }

  void _indexAlias(String alias, String canonical) {
    _aliasToCanonical[alias] = canonical;
    final relaxedAlias = stripIngredientDescriptors(alias);
    if (relaxedAlias.isNotEmpty) {
      _relaxedAliasToCanonical[relaxedAlias] = canonical;
    }
  }

  String? _bestContainsMatch(
    String normalized, {
    Map<String, String>? aliases,
  }) {
    final source = aliases ?? _aliasToCanonical;
    String? candidate;
    var candidateLength = -1;
    for (final entry in source.entries) {
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
