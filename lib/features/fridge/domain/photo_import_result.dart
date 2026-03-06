import 'detected_product_draft.dart';

class PhotoImportResult {
  final String imagePath;
  final List<DetectedProductDraft> drafts;
  final List<String> warnings;

  const PhotoImportResult({
    required this.imagePath,
    required this.drafts,
    this.warnings = const [],
  });

  PhotoImportResult copyWith({
    String? imagePath,
    List<DetectedProductDraft>? drafts,
    List<String>? warnings,
  }) {
    return PhotoImportResult(
      imagePath: imagePath ?? this.imagePath,
      drafts: drafts ?? this.drafts,
      warnings: warnings ?? this.warnings,
    );
  }
}
