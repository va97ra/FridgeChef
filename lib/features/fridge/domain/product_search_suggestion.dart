import '../../../core/utils/units.dart';

enum ProductSuggestionSource { recent, catalog }

class ProductSearchSuggestion {
  final String id;
  final String? catalogId;
  final String name;
  final String matchedText;
  final Unit defaultUnit;
  final ProductSuggestionSource source;
  final double score;
  final double? suggestedAmount;

  const ProductSearchSuggestion({
    required this.id,
    required this.catalogId,
    required this.name,
    required this.matchedText,
    required this.defaultUnit,
    required this.source,
    required this.score,
    this.suggestedAmount,
  });
}
