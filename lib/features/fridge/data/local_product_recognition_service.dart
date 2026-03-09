import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/units.dart';
import '../domain/detected_product_draft.dart';
import '../domain/photo_import_result.dart';
import '../domain/photo_import_utils.dart';
import '../domain/product_catalog_entry.dart';
import '../domain/product_search_suggestion.dart';
import 'product_catalog_repo.dart';

final localProductRecognitionServiceProvider =
    Provider<LocalProductRecognitionService>((ref) {
  return LocalProductRecognitionService(
    catalogRepo: ref.watch(productCatalogRepoProvider),
  );
});

class LocalProductRecognitionService {
  final ProductCatalogRepo catalogRepo;

  const LocalProductRecognitionService({
    required this.catalogRepo,
  });

  Future<PhotoImportResult> detectFromImage(String imagePath) async {
    final warnings = <String>[];
    final catalog = await catalogRepo.loadCatalog();
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final labeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.5),
    );

    try {
      final results = await Future.wait<dynamic>([
        recognizer.processImage(inputImage),
        labeler.processImage(inputImage),
      ]);
      final recognizedText = results[0] as RecognizedText;
      final labels = results[1] as List<ImageLabel>;

      final lines = recognizedText.blocks
          .expand((block) => block.lines)
          .map((line) => line.text)
          .where((line) => line.trim().isNotEmpty)
          .toList();

      final drafts = _buildDrafts(
        lines: lines,
        labels: labels,
        catalog: catalog,
      );

      if (drafts.isEmpty) {
        warnings
            .add('Не удалось уверенно распознать продукты, проверьте фото.');
      }

      return PhotoImportResult(
        imagePath: imagePath,
        drafts: drafts.isEmpty ? _fallbackUnknownDraft() : drafts,
        warnings: warnings,
      );
    } catch (_) {
      return PhotoImportResult(
        imagePath: imagePath,
        drafts: _fallbackUnknownDraft(),
        warnings: const [
          'Ошибка локального распознавания, добавьте продукт вручную.',
        ],
      );
    } finally {
      await recognizer.close();
      await labeler.close();
    }
  }

  List<DetectedProductDraft> _buildDrafts({
    required List<String> lines,
    required List<ImageLabel> labels,
    required List<ProductCatalogEntry> catalog,
  }) {
    final byKey = <String, DetectedProductDraft>{};
    final uuid = const Uuid();

    void upsertDraft({
      required String name,
      required double amount,
      required Unit unit,
      required double confidence,
      required String rawToken,
      String? matchedProductId,
      List<ProductSearchSuggestion> candidateMatches = const [],
    }) {
      final normalizedName = normalizeProductToken(name);
      if (normalizedName.isEmpty) {
        return;
      }
      final key = '$normalizedName|${unit.name}';
      final existing = byKey[key];
      if (existing == null) {
        byKey[key] = DetectedProductDraft(
          id: uuid.v4(),
          name: name,
          amount: amount,
          unit: unit,
          confidence: confidence.clamp(0.0, 1.0),
          rawTokens: [rawToken],
          source: DetectionSource.local,
          matchedProductId: matchedProductId,
          candidateMatches: candidateMatches,
        );
        return;
      }

      byKey[key] = existing.copyWith(
        amount: amount > existing.amount ? amount : existing.amount,
        confidence: confidence > existing.confidence
            ? confidence.clamp(0.0, 1.0)
            : existing.confidence,
        rawTokens: [...existing.rawTokens, rawToken],
        matchedProductId: matchedProductId ?? existing.matchedProductId,
        candidateMatches: existing.candidateMatches.isNotEmpty
            ? existing.candidateMatches
            : candidateMatches,
      );
    }

    for (final line in lines) {
      final candidates = findCatalogMatches(line, catalog, limit: 4);
      if (candidates.isEmpty) {
        continue;
      }
      final match = candidates.first;
      final amountUnit = tryExtractAmountUnit(line);
      upsertDraft(
        name: match.name,
        amount: amountUnit?.amount ?? 1,
        unit: amountUnit?.unit ?? match.defaultUnit,
        confidence: match.score,
        rawToken: line,
        matchedProductId: match.id,
        candidateMatches: candidates,
      );
    }

    for (final label in labels) {
      final candidates = findCatalogMatches(label.label, catalog, limit: 4);
      if (candidates.isEmpty) {
        continue;
      }
      final match = candidates.first;
      upsertDraft(
        name: match.name,
        amount: 1,
        unit: match.defaultUnit,
        confidence: ((match.score + label.confidence) / 2).clamp(0.0, 1.0),
        rawToken: label.label,
        matchedProductId: match.id,
        candidateMatches: candidates,
      );
    }

    final drafts = byKey.values.toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    return drafts.take(15).toList();
  }

  List<DetectedProductDraft> _fallbackUnknownDraft() {
    return const [
      DetectedProductDraft(
        id: 'unknown',
        name: 'Неопознанный продукт',
        amount: 1,
        unit: Unit.pcs,
        confidence: 0.2,
        rawTokens: ['unknown'],
        source: DetectionSource.local,
      ),
    ];
  }
}
