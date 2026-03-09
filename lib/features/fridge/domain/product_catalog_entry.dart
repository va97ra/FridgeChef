import '../../../core/utils/units.dart';

class ProductCatalogEntry {
  final String id;
  final String name;
  final String canonicalName;
  final List<String> synonyms;
  final Unit defaultUnit;

  const ProductCatalogEntry({
    required this.id,
    required this.name,
    String? canonicalName,
    required this.synonyms,
    this.defaultUnit = Unit.pcs,
  }) : canonicalName = canonicalName ?? name;

  factory ProductCatalogEntry.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    final normalizedId = (json['id'] as String?)?.trim();
    return ProductCatalogEntry(
      id: normalizedId != null && normalizedId.isNotEmpty
          ? normalizedId
          : _buildFallbackId(name),
      name: name,
      canonicalName: (json['canonicalName'] as String?)?.trim(),
      synonyms:
          (json['synonyms'] as List<dynamic>? ?? []).map((e) => '$e').toList(),
      defaultUnit: _parseUnit(
            (json['defaultUnit'] as String?)?.trim().toLowerCase(),
          ) ??
          _inferDefaultUnit(name),
    );
  }

  static String _buildFallbackId(String name) {
    return name
        .toLowerCase()
        .replaceAll('ё', 'е')
        .replaceAll(RegExp(r'[^a-zA-Zа-яА-Я0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }

  static Unit? _parseUnit(String? value) {
    switch (value) {
      case 'g':
      case 'гр':
      case 'г':
        return Unit.g;
      case 'kg':
      case 'кг':
        return Unit.kg;
      case 'ml':
      case 'мл':
        return Unit.ml;
      case 'l':
      case 'л':
        return Unit.l;
      case 'pcs':
      case 'шт':
        return Unit.pcs;
      default:
        return null;
    }
  }

  static Unit _inferDefaultUnit(String name) {
    final normalized = name.toLowerCase().replaceAll('ё', 'е');
    if (normalized.contains('яйц') ||
        normalized.contains('яблок') ||
        normalized.contains('банан') ||
        normalized.contains('огур') ||
        normalized.contains('помид') ||
        normalized.contains('апельсин') ||
        normalized.contains('лимон') ||
        normalized.contains('лук')) {
      return Unit.pcs;
    }
    if (normalized.contains('молок') ||
        normalized.contains('кефир') ||
        normalized.contains('йогурт') ||
        normalized.contains('вода') ||
        normalized.contains('сок')) {
      return Unit.l;
    }
    if (normalized.contains('масло') &&
        !normalized.contains('оливков') &&
        !normalized.contains('подсолнеч')) {
      return Unit.g;
    }
    if (normalized.contains('рис') ||
        normalized.contains('греч') ||
        normalized.contains('макарон') ||
        normalized.contains('мука') ||
        normalized.contains('сахар') ||
        normalized.contains('соль') ||
        normalized.contains('сыр') ||
        normalized.contains('творог') ||
        normalized.contains('куриц') ||
        normalized.contains('говядин') ||
        normalized.contains('свинин') ||
        normalized.contains('индейк') ||
        normalized.contains('рыб') ||
        normalized.contains('картоф') ||
        normalized.contains('морков') ||
        normalized.contains('капуст') ||
        normalized.contains('брокколи') ||
        normalized.contains('гриб')) {
      return Unit.g;
    }
    return Unit.pcs;
  }
}
