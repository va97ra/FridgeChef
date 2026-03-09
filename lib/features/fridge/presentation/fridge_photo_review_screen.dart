import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/utils/units.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../data/product_search_service.dart';
import '../domain/detected_product_draft.dart';
import '../domain/fridge_item.dart';
import '../domain/photo_import_result.dart';
import '../domain/photo_import_utils.dart';
import '../domain/product_search_suggestion.dart';
import 'providers.dart';

class FridgePhotoApplyResult {
  final int addedCount;
  final int mergedCount;

  const FridgePhotoApplyResult({
    required this.addedCount,
    required this.mergedCount,
  });
}

class FridgePhotoReviewScreen extends ConsumerStatefulWidget {
  final PhotoImportResult result;

  const FridgePhotoReviewScreen({
    super.key,
    required this.result,
  });

  @override
  ConsumerState<FridgePhotoReviewScreen> createState() =>
      _FridgePhotoReviewScreenState();
}

class _FridgePhotoReviewScreenState
    extends ConsumerState<FridgePhotoReviewScreen> {
  late List<DetectedProductDraft> _drafts;
  bool _saving = false;
  final Map<String, List<ProductSearchSuggestion>> _candidateMatches = {};

  @override
  void initState() {
    super.initState();
    final fridgeItems = ref.read(fridgeListProvider);
    _drafts = widget.result.drafts.map((draft) {
      final suggested = suggestMergeTargetId(
        draft: draft,
        fridgeItems: fridgeItems,
      );
      _candidateMatches[draft.id] = draft.candidateMatches;
      return draft.copyWith(mergeTargetFridgeItemId: suggested);
    }).toList();
    _primeCandidateMatches();
  }

  Future<void> _primeCandidateMatches() async {
    final service = ref.read(productSearchServiceProvider);
    final updates = <String, List<ProductSearchSuggestion>>{};

    for (final draft in _drafts) {
      if (_candidateMatches[draft.id]?.isNotEmpty ?? false) {
        continue;
      }
      updates[draft.id] = await service.search(draft.name, limit: 4);
    }

    if (!mounted || updates.isEmpty) {
      return;
    }

    setState(() {
      _candidateMatches.addAll(updates);
    });
  }

  Future<void> _refreshCandidatesForDraft(int index, String query) async {
    final service = ref.read(productSearchServiceProvider);
    final suggestions = query.trim().isEmpty
        ? await service.recentSuggestions(limit: 4)
        : await service.search(query, limit: 4);

    if (!mounted) {
      return;
    }

    final draft = _drafts[index];
    setState(() {
      _candidateMatches[draft.id] = suggestions;
      _drafts[index] = draft.copyWith(candidateMatches: suggestions);
    });
  }

  @override
  Widget build(BuildContext context) {
    final warnings = widget.result.warnings;

    return AppScaffold(
      title: 'Проверка распознавания',
      body: Column(
        children: [
          const SizedBox(height: 12),
          if (warnings.isNotEmpty) ...[
            _WarningsCard(warnings: warnings),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: _drafts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final draft = _drafts[index];
                final fridgeItems = ref.watch(fridgeListProvider);
                final suggestedMergeId = suggestMergeTargetId(
                  draft: draft,
                  fridgeItems: fridgeItems,
                );
                final mergeId =
                    draft.mergeTargetFridgeItemId ?? suggestedMergeId;
                final mergeTarget =
                    mergeId == null ? null : _findById(fridgeItems, mergeId);

                return _DraftCard(
                  draft: draft,
                  mergeTarget: mergeTarget,
                  candidates:
                      _candidateMatches[draft.id] ?? draft.candidateMatches,
                  onChanged: (updated) {
                    setState(() {
                      _drafts[index] = updated;
                    });
                  },
                  onNameChanged: (value) {
                    final updated = draft.copyWith(
                      name: value,
                      matchedProductId: null,
                      clearMergeTarget: true,
                    );
                    setState(() {
                      _drafts[index] = updated;
                    });
                    _refreshCandidatesForDraft(index, value);
                  },
                  onSuggestionSelected: (suggestion) {
                    final updated = draft.copyWith(
                      name: suggestion.name,
                      unit: draft.unit == Unit.pcs
                          ? suggestion.defaultUnit
                          : draft.unit,
                      matchedProductId: suggestion.catalogId,
                      candidateMatches:
                          _candidateMatches[draft.id] ?? draft.candidateMatches,
                      clearMergeTarget: true,
                    );
                    setState(() {
                      _drafts[index] = updated;
                    });
                  },
                  onMergeChanged: (enabled) {
                    setState(() {
                      _drafts[index] = draft.copyWith(
                        mergeTargetFridgeItemId:
                            enabled ? suggestedMergeId : null,
                        clearMergeTarget: !enabled,
                      );
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _applySelected,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.playlist_add_check_rounded),
              label: Text(_saving ? 'Сохраняю...' : 'Добавить выбранное'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  FridgeItem? _findById(List<FridgeItem> items, String id) {
    for (final item in items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  Future<void> _applySelected() async {
    setState(() => _saving = true);

    final notifier = ref.read(fridgeListProvider.notifier);
    final fridgeMap = {
      for (final item in ref.read(fridgeListProvider)) item.id: item,
    };

    var addedCount = 0;
    var mergedCount = 0;

    for (final draft in _drafts.where((entry) => entry.selected)) {
      final name = draft.name.trim();
      if (name.isEmpty) {
        continue;
      }
      final amount = draft.amount <= 0 ? 1.0 : draft.amount;
      final mergeId = draft.mergeTargetFridgeItemId;

      if (mergeId != null) {
        final target = fridgeMap[mergeId];
        if (target != null) {
          final converted = UnitConverter.convert(
            amount: amount,
            from: draft.unit,
            to: target.unit,
          );
          if (converted != null) {
            final updated = target.copyWith(amount: target.amount + converted);
            await notifier.updateItem(
              updated,
              productId: draft.matchedProductId,
            );
            fridgeMap[updated.id] = updated;
            mergedCount++;
            continue;
          }
        }
      }

      final newItem = FridgeItem(
        id: const Uuid().v4(),
        name: name,
        amount: amount,
        unit: draft.unit,
      );
      await notifier.addItem(newItem, productId: draft.matchedProductId);
      addedCount++;
    }

    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    Navigator.of(context).pop(
      FridgePhotoApplyResult(
        addedCount: addedCount,
        mergedCount: mergedCount,
      ),
    );
  }
}

class _WarningsCard extends StatelessWidget {
  final List<String> warnings;

  const _WarningsCard({required this.warnings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTokens.warn.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: AppTokens.warn.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Предупреждения',
            style: TextStyle(
              color: AppTokens.warn,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          ...warnings.map(
            (warning) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $warning',
                style: const TextStyle(
                  color: AppTokens.text,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  final DetectedProductDraft draft;
  final FridgeItem? mergeTarget;
  final List<ProductSearchSuggestion> candidates;
  final ValueChanged<DetectedProductDraft> onChanged;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<ProductSearchSuggestion> onSuggestionSelected;
  final ValueChanged<bool> onMergeChanged;

  const _DraftCard({
    required this.draft,
    required this.mergeTarget,
    required this.candidates,
    required this.onChanged,
    required this.onNameChanged,
    required this.onSuggestionSelected,
    required this.onMergeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.r16),
        boxShadow: AppTokens.cardShadow,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: draft.selected,
                onChanged: (value) =>
                    onChanged(draft.copyWith(selected: value ?? false)),
              ),
              Expanded(
                child: TextFormField(
                  key: ValueKey('${draft.id}-${draft.name}'),
                  initialValue: draft.name,
                  decoration: const InputDecoration(
                    labelText: 'Продукт',
                  ),
                  onChanged: onNameChanged,
                ),
              ),
              const SizedBox(width: 8),
              _ConfidenceBadge(confidence: draft.confidence),
            ],
          ),
          if (candidates.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: candidates.map((candidate) {
                  final isSelected = normalizeProductToken(candidate.name) ==
                      normalizeProductToken(draft.name);
                  return ChoiceChip(
                    label: Text(candidate.name),
                    selected: isSelected,
                    onSelected: (_) => onSuggestionSelected(candidate),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey(
                      '${draft.id}-${draft.amount}-${draft.unit.name}'),
                  initialValue: _formatAmount(draft.amount),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Количество',
                  ),
                  onChanged: (value) {
                    final parsed =
                        double.tryParse(value.replaceAll(',', '.')) ?? 1;
                    onChanged(draft.copyWith(amount: parsed <= 0 ? 1 : parsed));
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 120,
                child: DropdownButtonFormField<Unit>(
                  initialValue: draft.unit,
                  decoration: const InputDecoration(labelText: 'Ед.'),
                  items: Unit.values
                      .map(
                        (unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    onChanged(
                      draft.copyWith(
                        unit: value,
                        clearMergeTarget: true,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (mergeTarget != null) ...[
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              value: draft.mergeTargetFridgeItemId != null,
              onChanged: onMergeChanged,
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Объединить с "${mergeTarget!.name}"',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Текущее: ${_formatAmount(mergeTarget!.amount)} ${mergeTarget!.unit.label}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatAmount(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final double confidence;

  const _ConfidenceBadge({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).round().clamp(0, 100);
    final color = pct >= 75
        ? AppTokens.accent
        : (pct >= 45 ? AppTokens.secondary : AppTokens.warn);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppTokens.r8),
      ),
      child: Text(
        '$pct%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
