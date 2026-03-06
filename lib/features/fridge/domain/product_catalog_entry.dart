class ProductCatalogEntry {
  final String name;
  final List<String> synonyms;

  const ProductCatalogEntry({
    required this.name,
    required this.synonyms,
  });

  factory ProductCatalogEntry.fromJson(Map<String, dynamic> json) {
    return ProductCatalogEntry(
      name: json['name'] as String,
      synonyms:
          (json['synonyms'] as List<dynamic>? ?? []).map((e) => '$e').toList(),
    );
  }
}
