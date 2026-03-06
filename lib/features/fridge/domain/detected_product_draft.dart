import '../../../core/utils/units.dart';

enum DetectionSource { local, cloudRefined }

class DetectedProductDraft {
  final String id;
  final String name;
  final double amount;
  final Unit unit;
  final double confidence;
  final List<String> rawTokens;
  final DetectionSource source;
  final String? mergeTargetFridgeItemId;
  final bool selected;

  const DetectedProductDraft({
    required this.id,
    required this.name,
    required this.amount,
    required this.unit,
    required this.confidence,
    required this.rawTokens,
    required this.source,
    this.mergeTargetFridgeItemId,
    this.selected = true,
  });

  DetectedProductDraft copyWith({
    String? id,
    String? name,
    double? amount,
    Unit? unit,
    double? confidence,
    List<String>? rawTokens,
    DetectionSource? source,
    String? mergeTargetFridgeItemId,
    bool clearMergeTarget = false,
    bool? selected,
  }) {
    return DetectedProductDraft(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      confidence: confidence ?? this.confidence,
      rawTokens: rawTokens ?? this.rawTokens,
      source: source ?? this.source,
      mergeTargetFridgeItemId: clearMergeTarget
          ? null
          : (mergeTargetFridgeItemId ?? this.mergeTargetFridgeItemId),
      selected: selected ?? this.selected,
    );
  }
}
