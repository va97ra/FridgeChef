class ShelfItem {
  final String id;
  final String name;
  final bool inStock;
  final String? catalogId;
  final String canonicalName;
  final String category;
  final List<String> supportCanonicals;
  final bool isBlend;

  const ShelfItem({
    required this.id,
    required this.name,
    this.inStock = true,
    this.catalogId,
    String? canonicalName,
    this.category = 'other',
    this.supportCanonicals = const [],
    this.isBlend = false,
  }) : canonicalName = canonicalName ?? name;

  factory ShelfItem.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] as String? ?? '').trim();
    return ShelfItem(
      id: json['id'] as String,
      name: name,
      inStock: json['inStock'] as bool? ?? true,
      catalogId: (json['catalogId'] as String?)?.trim(),
      canonicalName:
          ((json['canonicalName'] as String?)?.trim().isNotEmpty ?? false)
              ? (json['canonicalName'] as String).trim()
              : name,
      category: (json['category'] as String? ?? 'other').trim(),
      supportCanonicals:
          ((json['supportCanonicals'] as List<dynamic>?) ?? const [])
              .map((value) => '$value')
              .where((value) => value.trim().isNotEmpty)
              .toList(),
      isBlend: json['isBlend'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'inStock': inStock,
      'catalogId': catalogId,
      'canonicalName': canonicalName,
      'category': category,
      'supportCanonicals': supportCanonicals,
      'isBlend': isBlend,
    };
  }

  ShelfItem copyWith({
    String? id,
    String? name,
    bool? inStock,
    String? catalogId,
    String? canonicalName,
    String? category,
    List<String>? supportCanonicals,
    bool? isBlend,
  }) {
    return ShelfItem(
      id: id ?? this.id,
      name: name ?? this.name,
      inStock: inStock ?? this.inStock,
      catalogId: catalogId ?? this.catalogId,
      canonicalName: canonicalName ?? this.canonicalName,
      category: category ?? this.category,
      supportCanonicals: supportCanonicals ?? this.supportCanonicals,
      isBlend: isBlend ?? this.isBlend,
    );
  }
}
