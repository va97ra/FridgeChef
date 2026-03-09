import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/units.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_surface.dart';
import '../data/fridge_photo_import_coordinator.dart';
import '../data/photo_input_service.dart';
import '../data/product_search_service.dart';
import '../domain/fridge_item.dart';
import '../domain/photo_source.dart';
import '../domain/product_search_suggestion.dart';
import 'fridge_photo_review_screen.dart';
import 'providers.dart';

class FridgeAddEditScreen extends ConsumerStatefulWidget {
  final FridgeItem? itemToEdit;

  const FridgeAddEditScreen({super.key, this.itemToEdit});

  @override
  ConsumerState<FridgeAddEditScreen> createState() =>
      _FridgeAddEditScreenState();
}

class _FridgeAddEditScreenState extends ConsumerState<FridgeAddEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _caloriesController;
  late final FocusNode _nameFocusNode;

  Unit _selectedUnit = Unit.g;
  DateTime? _expiresAt;
  List<ProductSearchSuggestion> _nameSuggestions = const [];
  bool _loadingSuggestions = false;
  bool _applyingSuggestion = false;
  int _suggestionRequestId = 0;
  String? _selectedProductId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.itemToEdit?.name);
    _amountController =
        TextEditingController(text: widget.itemToEdit?.amount.toString() ?? '');
    _caloriesController = TextEditingController(
      text: widget.itemToEdit?.calories?.toString() ?? '',
    );
    _nameFocusNode = FocusNode()..addListener(_handleNameFocusChanged);
    _selectedUnit = widget.itemToEdit?.unit ?? Unit.g;
    _expiresAt = widget.itemToEdit?.expiresAt;

    _nameController.addListener(_handleNameChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _refreshSuggestions();
    });
  }

  @override
  void dispose() {
    _nameController.removeListener(_handleNameChanged);
    _nameController.dispose();
    _amountController.dispose();
    _caloriesController.dispose();
    _nameFocusNode
      ..removeListener(_handleNameFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _handleNameChanged() {
    if (!_applyingSuggestion) {
      _selectedProductId = null;
    }
    _autoSelectUnit();
    if (_nameFocusNode.hasFocus) {
      _refreshSuggestions();
    }
  }

  void _handleNameFocusChanged() {
    if (_nameFocusNode.hasFocus) {
      _refreshSuggestions();
      return;
    }

    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (!mounted || _nameFocusNode.hasFocus) {
        return;
      }
      setState(() {
        _nameSuggestions = const [];
        _loadingSuggestions = false;
      });
    });
  }

  void _autoSelectUnit() {
    if (widget.itemToEdit != null || _selectedProductId != null) {
      return;
    }

    final text = _nameController.text.toLowerCase();

    if (text.contains('яйц') ||
        text.contains('яблок') ||
        text.contains('банан') ||
        text.contains('сосис')) {
      if (_selectedUnit != Unit.pcs) {
        setState(() => _selectedUnit = Unit.pcs);
      }
    } else if (text.contains('молок') ||
        text.contains('сок') ||
        text.contains('вод') ||
        text.contains('кефир')) {
      if (_selectedUnit != Unit.l && _selectedUnit != Unit.ml) {
        setState(() => _selectedUnit = Unit.l);
      }
    } else if (text.contains('мяс') ||
        text.contains('куриц') ||
        text.contains('говяд') ||
        text.contains('свинин') ||
        text.contains('картош') ||
        text.contains('сыр')) {
      if (_selectedUnit != Unit.kg && _selectedUnit != Unit.g) {
        setState(() => _selectedUnit = Unit.kg);
      }
    }
  }

  Future<void> _refreshSuggestions() async {
    final requestId = ++_suggestionRequestId;
    setState(() => _loadingSuggestions = true);

    final service = ref.read(productSearchServiceProvider);
    final query = _nameController.text.trim();
    final suggestions = query.isEmpty
        ? await service.recentSuggestions()
        : await service.search(query);

    if (!mounted || requestId != _suggestionRequestId) {
      return;
    }

    setState(() {
      _nameSuggestions = suggestions;
      _loadingSuggestions = false;
    });
  }

  void _applySuggestion(ProductSearchSuggestion suggestion) {
    _applyingSuggestion = true;
    _selectedProductId = suggestion.catalogId;
    _nameController.value = TextEditingValue(
      text: suggestion.name,
      selection: TextSelection.collapsed(offset: suggestion.name.length),
    );
    _selectedUnit = suggestion.defaultUnit;

    if ((_amountController.text.trim().isEmpty ||
            _amountController.text.trim() == '0') &&
        suggestion.suggestedAmount != null &&
        suggestion.suggestedAmount! > 0) {
      _amountController.text = _formatAmount(suggestion.suggestedAmount!);
    }

    setState(() {
      _nameSuggestions = const [];
    });
    _nameFocusNode.unfocus();
    _applyingSuggestion = false;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    final calories = int.tryParse(_caloriesController.text);

    final newItem = FridgeItem(
      id: widget.itemToEdit?.id ?? const Uuid().v4(),
      name: name,
      amount: amount,
      unit: _selectedUnit,
      expiresAt: _expiresAt,
      calories: calories,
    );

    if (widget.itemToEdit != null) {
      await ref.read(fridgeListProvider.notifier).updateItem(
            newItem,
            productId: _selectedProductId,
          );
    } else {
      await ref.read(fridgeListProvider.notifier).addItem(
            newItem,
            productId: _selectedProductId,
          );
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _startPhotoImport() async {
    final source = await showModalBottomSheet<PhotoSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Сделать фото'),
                onTap: () => Navigator.pop(context, PhotoSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Выбрать из галереи'),
                onTap: () => Navigator.pop(context, PhotoSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    _showLoadingDialog();
    final attempt =
        await ref.read(photoImportStateProvider.notifier).importFromPhoto(source);
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (!mounted || attempt.cancelled) {
      return;
    }

    if (!attempt.hasResult) {
      await _handlePhotoImportFailure(attempt);
      return;
    }

    final applyResult = await Navigator.push<FridgePhotoApplyResult>(
      context,
      MaterialPageRoute(
        builder: (_) => FridgePhotoReviewScreen(result: attempt.result!),
      ),
    );

    if (!mounted || applyResult == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Добавлено: ${applyResult.addedCount}, объединено: ${applyResult.mergedCount}',
        ),
      ),
    );
  }

  Future<void> _handlePhotoImportFailure(PhotoImportAttempt attempt) async {
    switch (attempt.permissionState) {
      case PhotoPermissionState.denied:
        await _showCameraDeniedDialog();
        return;
      case PhotoPermissionState.permanentlyDenied:
        await _showCameraSettingsDialog();
        return;
      case PhotoPermissionState.unavailable:
        await _showUnavailableMessage(attempt.source);
        return;
      case PhotoPermissionState.granted:
        final state = ref.read(photoImportStateProvider);
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
        return;
    }
  }

  Future<void> _showCameraDeniedDialog() async {
    final action = await showDialog<_PhotoPermissionAction>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Нужен доступ к камере'),
          content: const Text(
            'Разреши доступ к камере или выбери фото из галереи.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, _PhotoPermissionAction.gallery),
              child: const Text('Выбрать из галереи'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, _PhotoPermissionAction.retryCamera),
              child: const Text('Разрешить'),
            ),
          ],
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }
    if (action == _PhotoPermissionAction.gallery) {
      await _startDirectPhotoImport(PhotoSource.gallery);
      return;
    }
    await _startDirectPhotoImport(PhotoSource.camera);
  }

  Future<void> _showCameraSettingsDialog() async {
    final action = await showDialog<_PhotoPermissionAction>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Доступ к камере отключён'),
          content: const Text(
            'Включи камеру в системных настройках или выбери фото из галереи.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, _PhotoPermissionAction.gallery),
              child: const Text('Выбрать из галереи'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, _PhotoPermissionAction.openSettings),
              child: const Text('Открыть настройки'),
            ),
          ],
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }
    if (action == _PhotoPermissionAction.gallery) {
      await _startDirectPhotoImport(PhotoSource.gallery);
      return;
    }
    await ref.read(photoInputServiceProvider).openSettings();
  }

  Future<void> _showUnavailableMessage(PhotoSource source) async {
    if (source == PhotoSource.camera) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Камера недоступна. Можно выбрать фото из галереи.'),
          action: SnackBarAction(
            label: 'Галерея',
            onPressed: () => _startDirectPhotoImport(PhotoSource.gallery),
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Не удалось открыть фото. Попробуй снова.'),
      ),
    );
  }

  Future<void> _startDirectPhotoImport(PhotoSource source) async {
    _showLoadingDialog();
    final attempt =
        await ref.read(photoImportStateProvider.notifier).importFromPhoto(source);
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    if (!mounted || attempt.cancelled) {
      return;
    }
    if (!attempt.hasResult) {
      await _handlePhotoImportFailure(attempt);
      return;
    }

    final applyResult = await Navigator.push<FridgePhotoApplyResult>(
      context,
      MaterialPageRoute(
        builder: (_) => FridgePhotoReviewScreen(result: attempt.result!),
      ),
    );

    if (!mounted || applyResult == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Добавлено: ${applyResult.addedCount}, объединено: ${applyResult.mergedCount}',
        ),
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text('Распознаю продукты по фото...'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(1);
  }

  DateTime _quickExpiryDate(int daysFromNow) {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);
    return base.add(Duration(days: daysFromNow));
  }

  bool _isSameDate(DateTime? left, DateTime? right) {
    if (left == null || right == null) {
      return left == right;
    }
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.itemToEdit == null ? 'Добавить продукт' : 'Редактировать продукт',
      bodyPadding: const EdgeInsets.symmetric(horizontal: AppTokens.p16),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionSurface(
                      tone: SectionSurfaceTone.muted,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.p12,
                        vertical: AppTokens.p12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppTokens.primarySoft,
                                  borderRadius: BorderRadius.circular(
                                    AppTokens.r12,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: AppTokens.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: AppTokens.p8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Фото-импорт',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Быстро распознать продукты',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.p12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: _startPhotoImport,
                              icon: const Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                              ),
                              label: const Text('По фото'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTokens.p12),
                    SectionSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Основное',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: AppTokens.p12),
                          AppTextField(
                            controller: _nameController,
                            focusNode: _nameFocusNode,
                            label: 'Название продукта',
                            prefixIcon: const Icon(Icons.inventory_2_outlined),
                            suffixIcon: const Icon(Icons.search_rounded),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Введите название'
                                    : null,
                          ),
                          if (_loadingSuggestions) ...[
                            const SizedBox(height: AppTokens.p12),
                            const LinearProgressIndicator(minHeight: 2),
                          ],
                          if (_nameFocusNode.hasFocus && _nameSuggestions.isNotEmpty) ...[
                            const SizedBox(height: AppTokens.p12),
                            _SuggestionList(
                              suggestions: _nameSuggestions,
                              onSelected: _applySuggestion,
                            ),
                          ],
                          const SizedBox(height: AppTokens.p16),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: AppTextField(
                                  controller: _amountController,
                                  label: 'Количество',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  prefixIcon: const Icon(Icons.scale_outlined),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Обязательно';
                                    }
                                    final parsed =
                                        double.tryParse(value.replaceAll(',', '.'));
                                    if (parsed == null) {
                                      return 'Число';
                                    }
                                    if (parsed <= 0) {
                                      return '> 0';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: AppTokens.p12),
                              Expanded(
                                child: DropdownButtonFormField<Unit>(
                                  initialValue: _selectedUnit,
                                  decoration: const InputDecoration(
                                    labelText: 'Ед.',
                                  ),
                                  items: Unit.values
                                      .map(
                                        (unit) => DropdownMenuItem<Unit>(
                                          value: unit,
                                          child: Text(unit.label),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (unit) {
                                    if (unit == null) {
                                      return;
                                    }
                                    setState(() => _selectedUnit = unit);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.p20),
                          Container(
                            padding: const EdgeInsets.all(AppTokens.p16),
                            decoration: BoxDecoration(
                              color: AppTokens.surfaceRaised,
                              borderRadius: BorderRadius.circular(AppTokens.r16),
                              border: Border.all(color: AppTokens.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Срок годности',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(fontWeight: FontWeight.w700),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _expiresAt == null
                                                ? 'Не выбран'
                                                : Formatters.formatDate(_expiresAt!),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: _expiresAt == null
                                                      ? AppTokens.textLight
                                                      : AppTokens.primary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate: _expiresAt ?? DateTime.now(),
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime.now().add(
                                            const Duration(days: 365 * 5),
                                          ),
                                        );
                                        if (date != null) {
                                          setState(() => _expiresAt = date);
                                        }
                                      },
                                      icon: const Icon(Icons.calendar_today_rounded),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTokens.p8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _QuickExpiryChip(
                                      label: 'Сегодня',
                                      selected: _isSameDate(
                                        _expiresAt,
                                        _quickExpiryDate(0),
                                      ),
                                      onTap: () => setState(
                                        () => _expiresAt = _quickExpiryDate(0),
                                      ),
                                    ),
                                    _QuickExpiryChip(
                                      label: 'Завтра',
                                      selected: _isSameDate(
                                        _expiresAt,
                                        _quickExpiryDate(1),
                                      ),
                                      onTap: () => setState(
                                        () => _expiresAt = _quickExpiryDate(1),
                                      ),
                                    ),
                                    _QuickExpiryChip(
                                      label: '3 дня',
                                      selected: _isSameDate(
                                        _expiresAt,
                                        _quickExpiryDate(3),
                                      ),
                                      onTap: () => setState(
                                        () => _expiresAt = _quickExpiryDate(3),
                                      ),
                                    ),
                                    _QuickExpiryChip(
                                      label: 'Неделя',
                                      selected: _isSameDate(
                                        _expiresAt,
                                        _quickExpiryDate(7),
                                      ),
                                      onTap: () => setState(
                                        () => _expiresAt = _quickExpiryDate(7),
                                      ),
                                    ),
                                    _QuickExpiryChip(
                                      label: 'Без срока',
                                      selected: _expiresAt == null,
                                      onTap: () => setState(() => _expiresAt = null),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTokens.p16),
                          AppTextField(
                            controller: _caloriesController,
                            label: 'Калорийность (на 100г/шт) — опционально',
                            prefixIcon: const Icon(Icons.local_fire_department_outlined),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.p8),
          PrimaryButton(text: 'Сохранить', onPressed: _save),
          const SizedBox(height: AppTokens.p16),
        ],
      ),
    );
  }
}

enum _PhotoPermissionAction { retryCamera, gallery, openSettings }

class _SuggestionList extends StatelessWidget {
  final List<ProductSearchSuggestion> suggestions;
  final ValueChanged<ProductSearchSuggestion> onSelected;

  const _SuggestionList({
    required this.suggestions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SectionSurface(
      tone: SectionSurfaceTone.muted,
      withShadow: false,
      padding: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 220),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: AppTokens.border.withValues(alpha: 0.8),
          ),
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return ListTile(
              dense: true,
              leading: Icon(
                suggestion.source == ProductSuggestionSource.recent
                    ? Icons.history_rounded
                    : Icons.inventory_2_outlined,
                size: 18,
                color: AppTokens.textLight,
              ),
              title: Text(
                suggestion.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                suggestion.source == ProductSuggestionSource.recent
                    ? 'Из недавних'
                    : 'Похоже на: ${suggestion.matchedText}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                suggestion.defaultUnit.label,
                style: const TextStyle(
                  color: AppTokens.textLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () => onSelected(suggestion),
            );
          },
        ),
      ),
    );
  }
}

class _QuickExpiryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QuickExpiryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
