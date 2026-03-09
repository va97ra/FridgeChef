import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/features/shelf/data/pantry_catalog_repo.dart';
import 'package:help_to_cook/features/shelf/data/pantry_search_service.dart';
import 'package:help_to_cook/features/shelf/domain/pantry_catalog_entry.dart';

void main() {
  final catalog = [
    const PantryCatalogEntry(
      id: 'salt',
      name: 'Соль',
      canonicalName: 'соль',
      aliases: ['соль', 'поваренная соль'],
      category: 'basic',
      isStarter: true,
    ),
    const PantryCatalogEntry(
      id: 'oil',
      name: 'Подсолнечное масло',
      canonicalName: 'масло',
      aliases: ['подсолнечное масло', 'растительное масло', 'масло'],
      category: 'oil',
      supportCanonicals: ['жирная связка'],
      isStarter: true,
    ),
    const PantryCatalogEntry(
      id: 'mayo',
      name: 'Майонез',
      canonicalName: 'майонез',
      aliases: ['майонез'],
      category: 'sauce',
      supportCanonicals: ['жирная связка', 'мягкая связка'],
    ),
    const PantryCatalogEntry(
      id: 'chicken',
      name: 'Приправа для курицы',
      canonicalName: 'приправа для курицы',
      aliases: [
        'приправа для курицы',
        'магги для курицы',
        'maggi для курицы',
        'магги на второе для курицы',
        'kamis для курицы',
      ],
      category: 'blend',
      supportCanonicals: ['тёплая специя', 'умами акцент'],
      isBlend: true,
    ),
  ];

  test('returns starter pantry suggestions', () async {
    final service = PantrySearchService(
      catalogRepo: _FakePantryCatalogRepo(catalog),
    );

    final results = await service.starterSuggestions(limit: 2);

    expect(results, hasLength(2));
    expect(results.map((entry) => entry.name), contains('Соль'));
    expect(results.map((entry) => entry.name), contains('Подсолнечное масло'));
  });

  test('matches pantry aliases for shelf input', () async {
    final service = PantrySearchService(
      catalogRepo: _FakePantryCatalogRepo(catalog),
    );

    final results = await service.search('растительное');

    expect(results, isNotEmpty);
    expect(results.first.name, 'Подсолнечное масло');
  });

  test('supports fuzzy search for pantry items', () async {
    final service = PantrySearchService(
      catalogRepo: _FakePantryCatalogRepo(catalog),
    );

    final results = await service.search('майанез');

    expect(results, isNotEmpty);
    expect(results.first.name, 'Майонез');
  });

  test('maps brand seasoning alias to canonical pantry blend', () async {
    final service = PantrySearchService(
      catalogRepo: _FakePantryCatalogRepo(catalog),
    );

    final results = await service.search('магги на второе для курицы');

    expect(results, isNotEmpty);
    expect(results.first.name, 'Приправа для курицы');
    expect(results.first.isBlend, isTrue);
  });

  test('maps potato brand alias to canonical pantry blend', () async {
    final service = PantrySearchService(
      catalogRepo: _FakePantryCatalogRepo([
        ...catalog,
        const PantryCatalogEntry(
          id: 'potato',
          name: 'Приправа для картофеля',
          canonicalName: 'приправа для картофеля',
          aliases: [
            'приправа для картофеля',
            'магги на второе для картошки',
            'kamis для картофеля',
          ],
          category: 'blend',
          supportCanonicals: ['тёплая специя', 'умами акцент'],
          isBlend: true,
        ),
      ]),
    );

    final results = await service.search('магги на второе для картошки');

    expect(results, isNotEmpty);
    expect(results.first.name, 'Приправа для картофеля');
  });

  test('maps meat brand alias to canonical pantry blend', () async {
    final service = PantrySearchService(
      catalogRepo: _FakePantryCatalogRepo([
        ...catalog,
        const PantryCatalogEntry(
          id: 'meat',
          name: 'Приправа для мяса',
          canonicalName: 'приправа для мяса',
          aliases: [
            'приправа для мяса',
            'магги для свинины',
            'kamis для мяса',
          ],
          category: 'blend',
          supportCanonicals: ['тёплая специя', 'умами акцент'],
          isBlend: true,
        ),
      ]),
    );

    final results = await service.search('магги для свинины');

    expect(results, isNotEmpty);
    expect(results.first.name, 'Приправа для мяса');
  });

  test('maps bouillon cube alias to canonical pantry blend', () async {
    final service = PantrySearchService(
      catalogRepo: _FakePantryCatalogRepo([
        ...catalog,
        const PantryCatalogEntry(
          id: 'bouillon_cube',
          name: 'Куриный бульонный кубик',
          canonicalName: 'бульонный кубик',
          aliases: [
            'куриный бульонный кубик',
            'бульонный кубик куриный',
            'knorr куриный бульон',
            'maggi золотой бульон',
          ],
          category: 'blend',
          supportCanonicals: ['умами акцент', 'тёплая специя'],
          isBlend: true,
        ),
      ]),
    );

    final results = await service.search('knorr куриный бульон');

    expect(results, isNotEmpty);
    expect(results.first.name, 'Куриный бульонный кубик');
  });

  test('maps salad dressing alias to canonical pantry sauce', () async {
    final service = PantrySearchService(
      catalogRepo: _FakePantryCatalogRepo([
        ...catalog,
        const PantryCatalogEntry(
          id: 'caesar_dressing',
          name: 'Заправка Цезарь',
          canonicalName: 'заправка цезарь',
          aliases: [
            'заправка цезарь',
            'соус цезарь',
            'заправка для салата цезарь',
          ],
          category: 'sauce',
          supportCanonicals: [
            'мягкая связка',
            'умами акцент',
            'кислотный акцент',
          ],
        ),
      ]),
    );

    final results = await service.search('соус цезарь');

    expect(results, isNotEmpty);
    expect(results.first.name, 'Заправка Цезарь');
  });
}

class _FakePantryCatalogRepo extends PantryCatalogRepo {
  final List<PantryCatalogEntry> catalog;

  const _FakePantryCatalogRepo(this.catalog);

  @override
  Future<List<PantryCatalogEntry>> loadCatalog() async => catalog;
}
