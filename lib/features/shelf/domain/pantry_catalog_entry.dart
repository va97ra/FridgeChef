class PantryCatalogEntry {
  final String id;
  final String name;
  final String canonicalName;
  final List<String> aliases;
  final String category;
  final List<String> supportCanonicals;
  final bool isBlend;
  final bool isStarter;

  const PantryCatalogEntry({
    required this.id,
    required this.name,
    required this.canonicalName,
    required this.aliases,
    required this.category,
    this.supportCanonicals = const [],
    this.isBlend = false,
    this.isStarter = false,
  });

  factory PantryCatalogEntry.fromJson(Map<String, dynamic> json) {
    return PantryCatalogEntry(
      id: (json['id'] as String? ?? '').trim(),
      name: (json['name'] as String? ?? '').trim(),
      canonicalName: ((json['canonicalName'] as String?)?.trim().isNotEmpty ??
              false)
          ? (json['canonicalName'] as String).trim()
          : (json['name'] as String? ?? '').trim(),
      aliases:
          (json['aliases'] as List<dynamic>? ?? const []).map((e) => '$e').toList(),
      category: (json['category'] as String? ?? 'other').trim(),
      supportCanonicals: (json['supportCanonicals'] as List<dynamic>? ?? const [])
          .map((e) => '$e')
          .where((value) => value.trim().isNotEmpty)
          .toList(),
      isBlend: json['isBlend'] as bool? ?? false,
      isStarter: json['isStarter'] as bool? ?? false,
    );
  }
}

String pantryCategoryLabel(String category) {
  switch (category) {
    case 'basic':
      return 'База';
    case 'spice':
      return 'Специи';
    case 'herb':
      return 'Травы';
    case 'oil':
      return 'Масла';
    case 'sauce':
      return 'Соусы';
    case 'dairy':
      return 'Мягкая база';
    case 'blend':
      return 'Смеси';
    default:
      return 'Другое';
  }
}

String pantrySupportLabel(String canonical) {
  switch (canonical) {
    case 'тёплая специя':
      return 'Теплая специя';
    case 'травяной акцент':
      return 'Травяной акцент';
    case 'жирная связка':
      return 'Жирная связка';
    case 'мягкая связка':
      return 'Мягкая связка';
    case 'кислотный акцент':
      return 'Кислотный акцент';
    case 'томатная глубина':
      return 'Томатная глубина';
    case 'умами акцент':
      return 'Умами';
    case 'сладкий акцент':
      return 'Сладкий акцент';
    default:
      if (canonical.isEmpty) {
        return '';
      }
      return canonical[0].toUpperCase() + canonical.substring(1);
  }
}
