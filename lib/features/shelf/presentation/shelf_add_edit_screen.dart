import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../domain/shelf_item.dart';
import '../presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class ShelfAddEditScreen extends ConsumerStatefulWidget {
  final ShelfItem? itemToEdit;

  const ShelfAddEditScreen({super.key, this.itemToEdit});

  @override
  ConsumerState<ShelfAddEditScreen> createState() => _ShelfAddEditScreenState();
}

class _ShelfAddEditScreenState extends ConsumerState<ShelfAddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  bool _inStock = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.itemToEdit?.name);
    _inStock = widget.itemToEdit?.inStock ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();

      final newItem = ShelfItem(
        id: widget.itemToEdit?.id ?? const Uuid().v4(),
        name: name,
        inStock: _inStock,
      );

      if (widget.itemToEdit != null) {
        await ref.read(shelfListProvider.notifier).updateItem(newItem);
      } else {
        await ref.read(shelfListProvider.notifier).addItem(newItem);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.itemToEdit == null ? 'Добавить на полку' : 'Редактировать',
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
                      label: 'Название (соль, перец и т.д.)',
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Введите название' : null,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Сейчас есть в наличии'),
                      value: _inStock,
                      onChanged: (val) {
                        setState(() => _inStock = val);
                      },
                      activeThumbColor: AppTokens.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Сохранить',
                onPressed: _save,
              ),
              if (widget.itemToEdit != null) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    await ref
                        .read(shelfListProvider.notifier)
                        .removeItem(widget.itemToEdit!.id);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  child: const Text('Удалить',
                      style: TextStyle(color: AppTokens.warn)),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
