class ShelfItem {
  final String id;
  final String name;
  final bool inStock;

  const ShelfItem({
    required this.id,
    required this.name,
    this.inStock = true,
  });

  ShelfItem copyWith({
    String? id,
    String? name,
    bool? inStock,
  }) {
    return ShelfItem(
      id: id ?? this.id,
      name: name ?? this.name,
      inStock: inStock ?? this.inStock,
    );
  }
}
