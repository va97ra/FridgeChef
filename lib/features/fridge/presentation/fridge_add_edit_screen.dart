import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/utils/units.dart';
import '../../../core/utils/formatters.dart';
import '../domain/fridge_item.dart';
import '../presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/photo_source.dart';
import 'fridge_photo_review_screen.dart';

class FridgeAddEditScreen extends ConsumerStatefulWidget {
  final FridgeItem? itemToEdit;

  const FridgeAddEditScreen({super.key, this.itemToEdit});

  @override
  ConsumerState<FridgeAddEditScreen> createState() =>
      _FridgeAddEditScreenState();
}

class _FridgeAddEditScreenState extends ConsumerState<FridgeAddEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _caloriesController;

  Unit _selectedUnit = Unit.g;
  DateTime? _expiresAt;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.itemToEdit?.name);
    _amountController =
        TextEditingController(text: widget.itemToEdit?.amount.toString() ?? '');
    _caloriesController = TextEditingController(
        text: widget.itemToEdit?.calories?.toString() ?? '');
    _selectedUnit = widget.itemToEdit?.unit ?? Unit.g;
    _expiresAt = widget.itemToEdit?.expiresAt;

    // Умный автовыбор единицы измерения для популярных продуктов
    _nameController.addListener(_autoSelectUnit);
  }

  void _autoSelectUnit() {
    if (widget.itemToEdit != null) return; // Не меняем при редактировании

    final text = _nameController.text.toLowerCase();

    if (text.contains('яйц') ||
        text.contains('яблок') ||
        text.contains('банан') ||
        text.contains('сосис')) {
      if (_selectedUnit != Unit.pcs) setState(() => _selectedUnit = Unit.pcs);
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

  @override
  void dispose() {
    _nameController.removeListener(_autoSelectUnit);
    _nameController.dispose();
    _amountController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
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
        await ref.read(fridgeListProvider.notifier).updateItem(newItem);
      } else {
        await ref.read(fridgeListProvider.notifier).addItem(newItem);
      }

      if (mounted) {
        Navigator.pop(context);
      }
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
    final result = await ref
        .read(photoImportStateProvider.notifier)
        .importFromPhoto(source);
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (!mounted || result == null) {
      return;
    }

    final applyResult = await Navigator.push<FridgePhotoApplyResult>(
      context,
      MaterialPageRoute(
        builder: (_) => FridgePhotoReviewScreen(result: result),
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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.itemToEdit == null ? 'Добавить продукт' : 'Редактировать',
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _startPhotoImport,
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('Добавить по фото'),
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  children: [
                    AppTextField(
                      controller: _nameController,
                      label: 'Название продукта',
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Введите название' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: AppTextField(
                            controller: _amountController,
                            label: 'Количество',
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Обязательно';
                              }
                              final parsed =
                                  double.tryParse(v.replaceAll(',', '.'));
                              if (parsed == null) {
                                return 'Число';
                              }
                              if (parsed <= 0) return '> 0';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<Unit>(
                            initialValue: _selectedUnit,
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: AppTokens.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                    Radius.circular(AppTokens.r12)),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: Unit.values.map((u) {
                              return DropdownMenuItem(
                                value: u,
                                child: Text(u.label),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedUnit = v);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _caloriesController,
                      label: 'Калорийность (на 100г/шт) — опционально',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Срок годности'),
                      subtitle: Text(
                        _expiresAt == null
                            ? 'Не выбран'
                            : Formatters.formatDate(_expiresAt!),
                        style: TextStyle(
                            color: _expiresAt == null
                                ? AppTokens.textLight
                                : AppTokens.primary),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (date != null) {
                          setState(() => _expiresAt = date);
                        }
                      },
                    ),
                    if (_expiresAt != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => setState(() => _expiresAt = null),
                          child: const Text('Очистить'),
                        ),
                      )
                  ],
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Сохранить',
                onPressed: _save,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
