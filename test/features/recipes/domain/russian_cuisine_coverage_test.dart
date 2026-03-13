import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/features/recipes/domain/offline_chef_blueprints.dart';
import 'package:help_to_cook/features/recipes/domain/russian_cuisine_coverage.dart';

void main() {
  test('russian cuisine coverage ids are unique and documented', () {
    final ids = <String>{};

    for (final entry in russianCuisineCoverage) {
      expect(ids.add(entry.id), isTrue,
          reason: 'Duplicate coverage id: ${entry.id}');
      expect(entry.title, isNotEmpty, reason: 'Missing title for ${entry.id}');
      expect(
        entry.continuationNote.trim(),
        isNotEmpty,
        reason: 'Missing continuation note for ${entry.id}',
      );
    }
  });

  test('covered russian families map to explicit blueprints and family ids',
      () {
    for (final entry in russianCuisineCoverage) {
      if (entry.status != RussianCuisineCoverageStatus.covered) {
        continue;
      }

      expect(
        entry.blueprintId,
        isNotNull,
        reason: 'Covered entry ${entry.id} must point to a blueprint.',
      );

      final blueprint = chefBlueprints.firstWhere(
        (candidate) => candidate.id == entry.blueprintId,
      );

      expect(
        blueprint.tags,
        contains('russian_classic'),
        reason:
            'Covered Russian family ${entry.id} should keep russian_classic tag.',
      );
      expect(
        blueprint.dishFamily.name,
        entry.familyId,
        reason: 'Coverage family id mismatch for ${entry.id}.',
      );
    }
  });

  test('manifest preserves continuation state for future agents', () {
    final pendingEntries = russianCuisineCoverage
        .where((entry) => entry.status != RussianCuisineCoverageStatus.covered)
        .toList();

    expect(pendingEntries, isNotEmpty);
    expect(
      pendingEntries.first.id,
      isNotEmpty,
      reason: 'Future agents need a concrete next family from the manifest.',
    );

    for (final entry in pendingEntries) {
      if (entry.status == RussianCuisineCoverageStatus.blockedByCatalog) {
        expect(
          entry.blueprintId,
          isNull,
          reason:
              'Catalog-blocked entry ${entry.id} should not pretend to be covered.',
        );
      }
    }
  });
}
