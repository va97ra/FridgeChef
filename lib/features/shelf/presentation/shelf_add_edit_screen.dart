import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_surface.dart';
import '../../fridge/domain/photo_import_utils.dart';
import '../data/pantry_search_service.dart';
import '../domain/pantry_catalog_entry.dart';
import '../domain/shelf_item.dart';
import 'providers.dart';

class ShelfAddEditScreen extends ConsumerStatefulWidget {
  final ShelfItem? itemToEdit;

  const ShelfAddEditScreen({super.key, this.itemToEdit});

  @override
  ConsumerState<ShelfAddEditScreen> createState() => _ShelfAddEditScreenState();
}

class _ShelfAddEditScreenState extends ConsumerState<ShelfAddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  final _searchCounter = ValueNotifier<int>(0);
  bool _inStock = true;
  PantryCatalogEntry? _selectedEntry;
  List<PantryCatalogEntry> _starterItems = const [];
  List<PantryCatalogEntry> _suggestions = const [];
  bool _isLoadingSuggestions = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.itemToEdit?.name);
    _inStock = widget.itemToEdit?.inStock ?? true;
    if (widget.itemToEdit != null &&
        (widget.itemToEdit!.catalogId != null ||
            widget.itemToEdit!.supportCanonicals.isNotEmpty ||
            widget.itemToEdit!.category != 'other')) {
      _selectedEntry = PantryCatalogEntry(
        id: widget.itemToEdit!.catalogId ?? 'custom:${widget.itemToEdit!.id}',
        name: widget.itemToEdit!.name,
        canonicalName: widget.itemToEdit!.canonicalName,
        aliases: [widget.itemToEdit!.name],
        category: widget.itemToEdit!.category,
        supportCanonicals: widget.itemToEdit!.supportCanonicals,
        isBlend: widget.itemToEdit!.isBlend,
      );
    }
    _loadInitialSuggestions();
  }

  @override
  void dispose() {
    _searchCounter.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialSuggestions() async {
    final service = ref.read(pantrySearchServiceProvider);
    final starters = await service.starterSuggestions(limit: 10);
    if (!mounted) {
      return;
    }
    setState(() {
      _starterItems = starters;
    });
    await _updateSuggestions(_nameController.text);
  }

  Future<void> _updateSuggestions(String query) async {
    final requestId = _searchCounter.value + 1;
    _searchCounter.value = requestId;
    setState(() {
      _isLoadingSuggestions = true;
    });

    final service = ref.read(pantrySearchServiceProvider);
    final results = await service.search(query, limit: 8);
    if (!mounted || _searchCounter.value != requestId) {
      return;
    }

    final normalizedText = normalizeProductToken(query);
    final filtered = results.where((entry) {
      if (_selectedEntry?.id == entry.id &&
          normalizedText == normalizeProductToken(entry.name)) {
        return false;
      }
      return true;
    }).toList();

    setState(() {
      _suggestions = filtered;
      _isLoadingSuggestions = false;
    });
  }

  void _onNameChanged(String value) {
    if (_selectedEntry != null &&
        !_matchesSelectedEntry(value, _selectedEntry!)) {
      setState(() {
        _selectedEntry = null;
      });
    }
    _updateSuggestions(value);
  }

  bool _matchesSelectedEntry(String value, PantryCatalogEntry entry) {
    final normalized = normalizeProductToken(value);
    final variants = <String>{
      normalizeProductToken(entry.name),
      normalizeProductToken(entry.canonicalName),
      ...entry.aliases.map(normalizeProductToken),
    };
    return variants.contains(normalized);
  }

  void _selectEntry(PantryCatalogEntry entry) {
    setState(() {
      _selectedEntry = entry;
      _nameController.text = entry.name;
      _nameController.selection = TextSelection.collapsed(
        offset: _nameController.text.length,
      );
      _suggestions = const [];
    });
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final selectedEntry =
          _selectedEntry != null && _matchesSelectedEntry(name, _selectedEntry!)
              ? _selectedEntry
              : null;
      final selectedCatalogId =
          selectedEntry == null || selectedEntry.id.startsWith('custom:')
              ? null
              : selectedEntry.id;
      final newItem = ShelfItem(
        id: widget.itemToEdit?.id ?? const Uuid().v4(),
        name: name,
        inStock: _inStock,
        catalogId: selectedCatalogId,
        canonicalName: selectedEntry?.canonicalName ?? name,
        category: selectedEntry?.category ?? 'other',
        supportCanonicals: selectedEntry?.supportCanonicals ?? const [],
        isBlend: selectedEntry?.isBlend ?? false,
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
    final selectedEntry = _selectedEntry;

    return AppScaffold(
      title: widget.itemToEdit == null
          ? 'Добавить на полку'
          : 'Редактировать полку',
      body: Column(
        children: [
          const SizedBox(height: AppTokens.p12),
          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Что есть дома',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: AppTokens.p4),
                          Text(
                            'Выбирай специи, масла и соусы из pantry-каталога. Так движок точнее поймёт вкус блюда.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppTokens.p16),
                          AppTextField(
                            controller: _nameController,
                            label: 'Название на полке',
                            hintText: 'Например: соль, паприка, соевый соус',
                            prefixIcon: const Icon(Icons.spa_outlined),
                            onChanged: _onNameChanged,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Введите название'
                                : null,
                          ),
                          const SizedBox(height: AppTokens.p12),
                          Text(
                            'Популярное',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: AppTokens.p8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _starterItems.map((entry) {
                              final isSelected = selectedEntry?.id == entry.id;
                              return _PantryChoiceChip(
                                label: entry.name,
                                selected: isSelected,
                                onTap: () => _selectEntry(entry),
                              );
                            }).toList(),
                          ),
                          if (_isLoadingSuggestions) ...[
                            const SizedBox(height: AppTokens.p12),
                            const LinearProgressIndicator(minHeight: 2),
                          ] else if (_suggestions.isNotEmpty) ...[
                            const SizedBox(height: AppTokens.p12),
                            Container(
                              decoration: BoxDecoration(
                                color: AppTokens.surfaceRaised,
                                borderRadius:
                                    BorderRadius.circular(AppTokens.r16),
                                border: Border.all(color: AppTokens.border),
                              ),
                              child: Column(
                                children: _suggestions.map((entry) {
                                  return ListTile(
                                    dense: true,
                                    visualDensity: const VisualDensity(
                                      vertical: -2,
                                      horizontal: -2,
                                    ),
                                    title: Text(
                                      entry.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                              fontWeight: FontWeight.w700),
                                    ),
                                    subtitle: Text(
                                      pantryCategoryLabel(entry.category),
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    trailing: entry.isBlend
                                        ? const Icon(Icons.auto_awesome_rounded,
                                            size: 18)
                                        : const Icon(
                                            Icons.arrow_outward_rounded,
                                            size: 18),
                                    onTap: () => _selectEntry(entry),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                          if (selectedEntry != null) ...[
                            const SizedBox(height: AppTokens.p16),
                            Container(
                              padding: const EdgeInsets.all(AppTokens.p16),
                              decoration: BoxDecoration(
                                color: AppTokens.surfaceRaised,
                                borderRadius:
                                    BorderRadius.circular(AppTokens.r16),
                                border: Border.all(color: AppTokens.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          pantryCategoryLabel(
                                              selectedEntry.category),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                      if (selectedEntry.isBlend)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTokens.secondarySoft,
                                            borderRadius: BorderRadius.circular(
                                              AppTokens.pill,
                                            ),
                                          ),
                                          child: Text(
                                            'Смесь',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color:
                                                      AppTokens.secondaryDark,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (selectedEntry
                                      .supportCanonicals.isNotEmpty) ...[
                                    const SizedBox(height: AppTokens.p12),
                                    Text(
                                      'Как влияет на вкус',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: AppTokens.p8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: selectedEntry.supportCanonicals
                                          .map(
                                            (support) => _SupportBadge(
                                              label:
                                                  pantrySupportLabel(support),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: AppTokens.p16),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTokens.surfaceRaised,
                              borderRadius:
                                  BorderRadius.circular(AppTokens.r16),
                              border: Border.all(color: AppTokens.border),
                            ),
                            child: SwitchListTile(
                              title: const Text('Есть в наличии'),
                              subtitle: const Text(
                                  'Эта позиция будет учитываться при подборе блюд'),
                              value: _inStock,
                              onChanged: (val) =>
                                  setState(() => _inStock = val),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppTokens.p16,
                                vertical: 4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.p12),
          PrimaryButton(text: 'Сохранить', onPressed: _save),
          if (widget.itemToEdit != null) ...[
            const SizedBox(height: AppTokens.p8),
            PrimaryButton(
              text: 'Удалить',
              onPressed: () async {
                await ref
                    .read(shelfListProvider.notifier)
                    .removeItem(widget.itemToEdit!.id);
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              variant: PrimaryButtonVariant.ghost,
            ),
          ],
          const SizedBox(height: AppTokens.p20),
        ],
      ),
    );
  }
}

class _PantryChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PantryChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTokens.accentSoft : AppTokens.surfaceRaised,
          borderRadius: BorderRadius.circular(AppTokens.pill),
          border: Border.all(
            color: selected ? AppTokens.accent : AppTokens.border,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? AppTokens.accent : AppTokens.text,
              ),
        ),
      ),
    );
  }
}

class _SupportBadge extends StatelessWidget {
  final String label;

  const _SupportBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.pill),
        border: Border.all(color: AppTokens.border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
