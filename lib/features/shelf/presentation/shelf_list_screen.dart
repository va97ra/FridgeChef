import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_state_panel.dart';
import '../../../core/widgets/section_surface.dart';
import '../../fridge/domain/photo_import_utils.dart';
import '../domain/pantry_catalog_entry.dart';
import '../domain/shelf_item.dart';
import 'providers.dart';
import 'shelf_add_edit_screen.dart';
import 'widgets/shelf_item_chip.dart';

class ShelfListScreen extends ConsumerStatefulWidget {
  const ShelfListScreen({super.key});

  @override
  ConsumerState<ShelfListScreen> createState() => _ShelfListScreenState();
}

class _ShelfListScreenState extends ConsumerState<ShelfListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  _ShelfAvailabilityFilter _availabilityFilter = _ShelfAvailabilityFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(shelfListProvider);
    final inStock = items.where((i) => i.inStock).length;
    final availableCategories = _availableCategories(items);
    final filteredItems = _filterItems(items);
    final groupedItems = _groupShelfItems(filteredItems);

    return AppScaffold(
      title: 'Полка',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: AppIconButton(
            icon: Icons.add_rounded,
            onPressed: () => Navigator.push(
              context,
              AppRoutes.fadeThroughRoute(page: const ShelfAddEditScreen()),
            ),
            tone: AppIconButtonTone.primary,
            tooltip: 'Добавить на полку',
          ),
        ),
      ],
      body: items.isEmpty
          ? const _ShelfEmptyState()
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppTokens.p8),
                  Row(
                    children: [
                      Expanded(
                        child: _ShelfMetric(
                          icon: Icons.spa_outlined,
                          label: 'В наличии',
                          value: '$inStock',
                        ),
                      ),
                      const SizedBox(width: AppTokens.p12),
                      Expanded(
                        child: _ShelfMetric(
                          icon: Icons.inventory_2_outlined,
                          label: 'Всего позиций',
                          value: '${items.length}',
                          tone: SectionSurfaceTone.base,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.p16),
                  Text(
                    'Специи, масла и соусы',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppTokens.p4),
                  Text(
                    'Отмечай, что есть дома. Это влияет на вкус и точность рецептов.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppTokens.p16),
                  SectionSurface(
                    tone: SectionSurfaceTone.muted,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(
                          key: const ValueKey('shelf-search-field'),
                          label: 'Поиск по полке',
                          controller: _searchController,
                          hintText: 'Соль, соусы, смеси, маринады',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                  tooltip: 'Очистить поиск',
                                ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                        const SizedBox(height: AppTokens.p12),
                        Wrap(
                          spacing: AppTokens.p8,
                          runSpacing: AppTokens.p8,
                          children: [
                            _ShelfCategoryFilterChip(
                              key: const ValueKey('shelf-availability-all'),
                              label: 'Все',
                              selected: _availabilityFilter ==
                                  _ShelfAvailabilityFilter.all,
                              onSelected: () {
                                setState(() {
                                  _availabilityFilter =
                                      _ShelfAvailabilityFilter.all;
                                });
                              },
                            ),
                            _ShelfCategoryFilterChip(
                              key: const ValueKey('shelf-availability-in'),
                              label: 'Есть дома',
                              selected: _availabilityFilter ==
                                  _ShelfAvailabilityFilter.inStock,
                              onSelected: () {
                                setState(() {
                                  _availabilityFilter =
                                      _ShelfAvailabilityFilter.inStock;
                                });
                              },
                            ),
                            _ShelfCategoryFilterChip(
                              key: const ValueKey('shelf-availability-out'),
                              label: 'Нет',
                              selected: _availabilityFilter ==
                                  _ShelfAvailabilityFilter.outOfStock,
                              onSelected: () {
                                setState(() {
                                  _availabilityFilter =
                                      _ShelfAvailabilityFilter.outOfStock;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTokens.p12),
                        Wrap(
                          spacing: AppTokens.p8,
                          runSpacing: AppTokens.p8,
                          children: [
                            _ShelfCategoryFilterChip(
                              key: const ValueKey('shelf-filter-all'),
                              label: 'Все',
                              selected: _selectedCategory == null,
                              onSelected: () {
                                setState(() {
                                  _selectedCategory = null;
                                });
                              },
                            ),
                            for (final category in availableCategories)
                              _ShelfCategoryFilterChip(
                                key: ValueKey('shelf-filter-$category'),
                                label: pantryCategoryLabel(category),
                                selected: _selectedCategory == category,
                                onSelected: () {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.p16),
                  if (filteredItems.isEmpty)
                    _ShelfFilteredEmptyState(
                      onReset: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _selectedCategory = null;
                          _availabilityFilter = _ShelfAvailabilityFilter.all;
                        });
                      },
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final group in groupedItems) ...[
                          _ShelfCategorySection(
                            category: group.$1,
                            items: group.$2,
                          ),
                          const SizedBox(height: AppTokens.p16),
                        ],
                      ],
                    ),
                ],
              ),
            ),
    );
  }

  List<ShelfItem> _filterItems(List<ShelfItem> items) {
    return items.where((item) {
      if (_selectedCategory != null && item.category != _selectedCategory) {
        return false;
      }
      if (_availabilityFilter == _ShelfAvailabilityFilter.inStock &&
          !item.inStock) {
        return false;
      }
      if (_availabilityFilter == _ShelfAvailabilityFilter.outOfStock &&
          item.inStock) {
        return false;
      }

      final query = normalizeProductToken(_searchQuery);
      if (query.isEmpty) {
        return true;
      }

      final haystack = <String>{
        normalizeProductToken(item.name),
        normalizeProductToken(item.canonicalName),
        normalizeProductToken(pantryCategoryLabel(item.category)),
        ...item.supportCanonicals.map(normalizeProductToken),
      };
      return haystack.any(
        (token) =>
            token.isNotEmpty &&
            (token.contains(query) || query.contains(token)),
      );
    }).toList();
  }

  List<String> _availableCategories(List<ShelfItem> items) {
    final categories = items.map((item) => item.category).toSet().toList()
      ..sort((a, b) {
        final byCategory =
            _categoryOrderValue(a).compareTo(_categoryOrderValue(b));
        if (byCategory != 0) {
          return byCategory;
        }
        return pantryCategoryLabel(a).compareTo(pantryCategoryLabel(b));
      });
    return categories;
  }
}

class _ShelfCategorySection extends ConsumerWidget {
  final String category;
  final List<ShelfItem> items;

  const _ShelfCategorySection({
    required this.category,
    required this.items,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              pantryCategoryLabel(category),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(width: AppTokens.p8),
            Text(
              '${items.length}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTokens.textLight,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.p8),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: items.map((item) {
            return ShelfItemChip(
              item: item,
              onToggle: () =>
                  ref.read(shelfListProvider.notifier).toggleItem(item),
              onLongPress: () {
                Navigator.push(
                  context,
                  AppRoutes.fadeThroughRoute(
                    page: ShelfAddEditScreen(itemToEdit: item),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ShelfEmptyState extends StatelessWidget {
  const _ShelfEmptyState();

  @override
  Widget build(BuildContext context) {
    return EmptyStatePanel(
      icon: Icons.spa_outlined,
      title: 'Полка пока пустая',
      description:
          'Добавляй специи, масла и соусы по одной позиции через +. Так будет точно понятно, что реально есть дома.',
      actionLabel: 'Добавить на полку',
      onAction: () => Navigator.push(
        context,
        AppRoutes.fadeThroughRoute(page: const ShelfAddEditScreen()),
      ),
      iconColor: AppTokens.secondaryDark,
      iconBackground: AppTokens.secondarySoft,
    );
  }
}

class _ShelfFilteredEmptyState extends StatelessWidget {
  final VoidCallback onReset;

  const _ShelfFilteredEmptyState({
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SectionSurface(
        tone: SectionSurfaceTone.muted,
        padding: const EdgeInsets.all(AppTokens.p20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 28,
              color: AppTokens.textLight,
            ),
            const SizedBox(height: AppTokens.p12),
            Text(
              'Ничего не найдено',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.p4),
            Text(
              'Попробуй другой запрос или сбрось фильтр категории.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.p12),
            OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Сбросить фильтры'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShelfCategoryFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _ShelfCategoryFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppTokens.insetSurfaceStrong,
      backgroundColor: AppTokens.surface,
      labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: selected ? AppTokens.text : AppTokens.textLight,
          ),
      side: BorderSide(
        color: selected ? AppTokens.outlineStrong : AppTokens.border,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.pill),
      ),
      visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.p8,
        vertical: AppTokens.p4,
      ),
    );
  }
}

class _ShelfMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final SectionSurfaceTone tone;

  const _ShelfMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.tone = SectionSurfaceTone.base,
  });

  @override
  Widget build(BuildContext context) {
    return SectionSurface(
      tone: tone,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.p16,
        vertical: AppTokens.p12,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTokens.textLight),
          const SizedBox(width: AppTokens.p8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<(String, List<ShelfItem>)> _groupShelfItems(List<ShelfItem> items) {
  final grouped = <String, List<ShelfItem>>{};
  for (final item in items) {
    grouped.putIfAbsent(item.category, () => []).add(item);
  }

  final result = grouped.entries.toList()
    ..sort((a, b) {
      final byCategory = _categoryOrderValue(a.key).compareTo(
        _categoryOrderValue(b.key),
      );
      if (byCategory != 0) {
        return byCategory;
      }
      return a.key.compareTo(b.key);
    });
  return result
      .map(
        (entry) => (
          entry.key,
          (entry.value
            ..sort((a, b) {
              if (a.inStock != b.inStock) {
                return a.inStock ? -1 : 1;
              }
              return a.name.compareTo(b.name);
            }))
        ),
      )
      .toList();
}

int _categoryOrderValue(String category) {
  const categoryOrder = {
    'basic': 0,
    'spice': 1,
    'herb': 2,
    'oil': 3,
    'sauce': 4,
    'dairy': 5,
    'blend': 6,
    'other': 7,
  };
  return categoryOrder[category] ?? 99;
}

enum _ShelfAvailabilityFilter { all, inStock, outOfStock }
