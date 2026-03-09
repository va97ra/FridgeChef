import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../fridge/domain/photo_import_utils.dart';
import '../domain/pantry_catalog_entry.dart';
import 'pantry_catalog_repo.dart';

final pantrySearchServiceProvider = Provider<PantrySearchService>((ref) {
  return PantrySearchService(
    catalogRepo: ref.watch(pantryCatalogRepoProvider),
  );
});

class PantrySearchService {
  final PantryCatalogRepo catalogRepo;

  const PantrySearchService({
    required this.catalogRepo,
  });

  Future<List<PantryCatalogEntry>> starterSuggestions({int limit = 10}) async {
    final catalog = await catalogRepo.loadCatalog();
    return catalog.where((entry) => entry.isStarter).take(limit).toList();
  }

  Future<List<PantryCatalogEntry>> search(
    String query, {
    int limit = 8,
  }) async {
    final normalized = normalizeProductToken(query);
    if (normalized.isEmpty) {
      return starterSuggestions(limit: limit);
    }

    final catalog = await catalogRepo.loadCatalog();
    final ranked = <_PantrySearchMatch>[];

    for (final entry in catalog) {
      final aliases = <String>{
        normalizeProductToken(entry.name),
        normalizeProductToken(entry.canonicalName),
        ...entry.aliases.map(normalizeProductToken),
      };

      double? bestScore;
      for (final alias in aliases) {
        if (alias.isEmpty) {
          continue;
        }
        final score = _scoreAlias(normalized, alias);
        if (score == null) {
          continue;
        }
        if (bestScore == null || score > bestScore) {
          bestScore = score;
        }
      }

      if (bestScore == null) {
        continue;
      }

      ranked.add(_PantrySearchMatch(entry: entry, score: bestScore));
    }

    ranked.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) {
        return byScore;
      }
      if (a.entry.isStarter != b.entry.isStarter) {
        return a.entry.isStarter ? -1 : 1;
      }
      return a.entry.name.compareTo(b.entry.name);
    });

    return ranked.take(limit).map((match) => match.entry).toList();
  }

  double? _scoreAlias(String query, String alias) {
    if (query == alias) {
      return 0.99;
    }
    if (alias.startsWith(query)) {
      return 0.94;
    }
    if (query.startsWith(alias)) {
      return 0.88;
    }
    if (alias.contains(query)) {
      return 0.82;
    }
    if (query.contains(alias)) {
      return 0.79;
    }

    final distance = _levenshteinDistance(query, alias);
    final maxDistance = query.length <= 5 ? 1 : 2;
    if (distance > maxDistance) {
      return null;
    }
    return 0.70 - (distance * 0.08);
  }
}

class _PantrySearchMatch {
  final PantryCatalogEntry entry;
  final double score;

  const _PantrySearchMatch({
    required this.entry,
    required this.score,
  });
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
