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
    _amountController = TextEditingController(
        text: widget.itemToEdit?.amount.toString() ?? '');
    _caloriesController = TextEditingController(
        text: widget.itemToEdit?.calories?.toString() ?? '');
    _selectedUnit = widget.itemToEdit?.unit ?? Unit.g;
    _expiresAt = widget.itemToEdit?.expiresAt;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final amount = double.tryParse(_amountController.text) ?? 0.0;
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
        ref.read(fridgeListProvider.notifier).updateItem(newItem);
      } else {
        ref.read(fridgeListProvider.notifier).addItem(newItem);
      }

      Navigator.pop(context);
    }
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
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Обязательно';
                              if (double.tryParse(v) == null) {
                                return 'Число';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<Unit>(
                            value: _selectedUnit,
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: AppTokens.surface,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(AppTokens.r12)),
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
                          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
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
