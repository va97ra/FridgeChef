import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_state_panel.dart';
import '../data/fridge_photo_import_coordinator.dart';
import '../data/photo_input_service.dart';
import '../domain/fridge_item.dart';
import '../domain/photo_source.dart';
import 'fridge_add_edit_screen.dart';
import 'fridge_photo_review_screen.dart';
import 'providers.dart';
import 'widgets/fridge_item_card.dart';

class FridgeListScreen extends ConsumerStatefulWidget {
  const FridgeListScreen({super.key});

  @override
  ConsumerState<FridgeListScreen> createState() => _FridgeListScreenState();
}

// Категории для фильтрации — ключевые слова сгруппированы по смыслу
enum _FridgeCategory {
  all,
  dairy,
  meat,
  veggies,
  grains,
  eggs,
  other,
}

extension _FridgeCategoryExt on _FridgeCategory {
  String get label => switch (this) {
        _FridgeCategory.all => 'Все',
        _FridgeCategory.dairy => '🥛 Молочное',
        _FridgeCategory.meat => '🥩 Мясо',
        _FridgeCategory.veggies => '🥦 Овощи',
        _FridgeCategory.grains => '🌾 Крупы',
        _FridgeCategory.eggs => '🥚 Яйца',
        _FridgeCategory.other => '📦 Прочее',
      };

  bool matches(String name) {
    final n = name.toLowerCase();
    return switch (this) {
      _FridgeCategory.all => true,
      _FridgeCategory.dairy => n.contains('молок') ||
          n.contains('кефир') ||
          n.contains('йогурт') ||
          n.contains('сыр') ||
          n.contains('творог') ||
          n.contains('сметан') ||
          n.contains('ряженк') ||
          n.contains('масл') && !n.contains('подсолн') && !n.contains('оливк'),
      _FridgeCategory.meat => n.contains('куриц') ||
          n.contains('фарш') ||
          n.contains('сосиск') ||
          n.contains('мяс') ||
          n.contains('свинин') ||
          n.contains('говядин') ||
          n.contains('колбас') ||
          n.contains('рыб') ||
          n.contains('тефтел'),
      _FridgeCategory.veggies => n.contains('помид') ||
          n.contains('огур') ||
          n.contains('морков') ||
          n.contains('капуст') ||
          n.contains('кабач') ||
          n.contains('картош') ||
          n.contains('лук') ||
          n.contains('чеснок') ||
          n.contains('перец') ||
          n.contains('баклажан') ||
          n.contains('свёкл') ||
          n.contains('свекл') ||
          n.contains('зелен'),
      _FridgeCategory.grains => n.contains('рис') ||
          n.contains('греч') ||
          n.contains('макарон') ||
          n.contains('кускус') ||
          n.contains('овсян') ||
          n.contains('пшен') ||
          n.contains('хлеб') ||
          n.contains('мука') ||
          n.contains('батон'),
      _FridgeCategory.eggs => n.contains('яйц'),
      _FridgeCategory.other =>
        true, // показывается только когда ни одна другая не совпала
    };
  }
}

class _FridgeListScreenState extends ConsumerState<FridgeListScreen> {
  late final TextEditingController _searchController;
  String _query = '';
  _FridgeCategory _categoryFilter = _FridgeCategory.all;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(fridgeListProvider);
    final filteredItems = _filterItems(items, _query);
    final expiringSoon = items.where((item) {
      if (item.expiresAt == null) {
        return false;
      }
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final expiry = DateTime(
        item.expiresAt!.year,
        item.expiresAt!.month,
        item.expiresAt!.day,
      );
      return expiry.difference(today).inDays <= 3;
    }).length;

    return AppScaffold(
      title: 'Мой холодильник',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: AppIconButton(
            icon: Icons.camera_alt_rounded,
            onPressed: _startPhotoImport,
            tone: AppIconButtonTone.secondary,
            tooltip: 'Добавить по фото',
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: AppIconButton(
            icon: Icons.add_rounded,
            onPressed: _openAddScreen,
            tone: AppIconButtonTone.primary,
            tooltip: 'Добавить продукт',
          ),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Компактная строка статистики
          _StatRow(total: items.length, expiringSoon: expiringSoon),
          const SizedBox(height: AppTokens.p12),
          // Горизонтальные фильтры по категориям
          if (items.isNotEmpty)
            _CategoryFilterBar(
              selected: _categoryFilter,
              items: items,
              onChanged: (cat) => setState(() => _categoryFilter = cat),
            ),
          if (items.isNotEmpty) const SizedBox(height: AppTokens.p12),
          // Поиск — только когда продуктов >= 6
          if (items.length >= 6)
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Поиск продукта',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          if (items.length >= 6) const SizedBox(height: AppTokens.p12),
          Expanded(
            child: items.isEmpty
                ? EmptyStatePanel(
                    icon: Icons.kitchen_outlined,
                    title: 'Холодильник пока пуст',
                    description:
                        'Добавь продукты вручную или по фото, чтобы приложение могло подобрать лучшие блюда.',
                    actionLabel: 'Добавить продукт',
                    onAction: _openAddScreen,
                    iconColor: AppTokens.accent,
                    iconBackground: AppTokens.accentSoft,
                  )
                : filteredItems.isEmpty
                    ? const EmptyStatePanel(
                        icon: Icons.search_off_rounded,
                        title: 'Ничего не найдено',
                        description:
                            'Попробуй другое название, другую категорию или очисти фильтры.',
                        iconColor: AppTokens.info,
                        iconBackground: AppTokens.infoSoft,
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredItems.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppTokens.p12),
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return Dismissible(
                            key: ValueKey(item.id),
                            direction: DismissDirection.endToStart,
                            background: _buildDismissBackground(),
                            onDismissed: (_) {
                              ref
                                  .read(fridgeListProvider.notifier)
                                  .removeItem(item.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${item.name} удалён'),
                                  action: SnackBarAction(
                                    label: 'Отменить',
                                    onPressed: () => ref
                                        .read(fridgeListProvider.notifier)
                                        .addItem(item),
                                  ),
                                ),
                              );
                            },
                            child: FridgeItemCard(
                              item: item,
                              onTap: () => Navigator.push(
                                context,
                                AppRoutes.fadeThroughRoute(
                                  page: FridgeAddEditScreen(itemToEdit: item),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _openAddScreen() {
    Navigator.push(
      context,
      AppRoutes.fadeThroughRoute(page: const FridgeAddEditScreen()),
    );
  }

  List<FridgeItem> _filterItems(List<FridgeItem> items, String query) {
    var result = items;

    // Фильтр по категории
    if (_categoryFilter != _FridgeCategory.all) {
      if (_categoryFilter == _FridgeCategory.other) {
        // «Прочее» — то, что не попало ни в одну из известных категорий
        final known = [
          _FridgeCategory.dairy,
          _FridgeCategory.meat,
          _FridgeCategory.veggies,
          _FridgeCategory.grains,
          _FridgeCategory.eggs,
        ];
        result = result
            .where((item) => !known.any((cat) => cat.matches(item.name)))
            .toList();
      } else {
        result =
            result.where((item) => _categoryFilter.matches(item.name)).toList();
      }
    }

    // Фильтр по поисковому запросу
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return result;
    }
    return result
        .where((item) => item.name.toLowerCase().contains(normalized))
        .toList();
  }

  Widget _buildDismissBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTokens.warnSoft,
        borderRadius: BorderRadius.circular(AppTokens.r20),
      ),
      child: const Icon(Icons.delete_outline_rounded, color: AppTokens.warn),
    );
  }

  Future<void> _startPhotoImport() async {
    final source = await showModalBottomSheet<PhotoSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _PhotoSourceSheet(),
    );
    if (source == null) {
      return;
    }

    _showLoadingDialog();
    final attempt = await ref
        .read(photoImportStateProvider.notifier)
        .importFromPhoto(source);
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

    final result = attempt.result!;

    if (!mounted) {
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
            'Разреши доступ к камере или выбери уже готовое фото из галереи.',
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
      await _runPhotoImport(PhotoSource.gallery);
      return;
    }
    await _runPhotoImport(PhotoSource.camera);
  }

  Future<void> _showCameraSettingsDialog() async {
    final action = await showDialog<_PhotoPermissionAction>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Доступ к камере отключён'),
          content: const Text(
            'Камера запрещена на уровне системы. Открой настройки или выбери фото из галереи.',
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
      await _runPhotoImport(PhotoSource.gallery);
      return;
    }
    await ref.read(photoInputServiceProvider).openSettings();
  }

  Future<void> _showUnavailableMessage(PhotoSource source) async {
    if (source == PhotoSource.camera) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Камера недоступна. Можно выбрать фото из галереи.'),
          action: SnackBarAction(
            label: 'Галерея',
            onPressed: () => _runPhotoImport(PhotoSource.gallery),
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

  Future<void> _runPhotoImport(PhotoSource source) async {
    _showLoadingDialog();
    final attempt = await ref
        .read(photoImportStateProvider.notifier)
        .importFromPhoto(source);
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
}

enum _PhotoPermissionAction { retryCamera, gallery, openSettings }

/// Компактная строка со статистикой — заменяет два больших MetricPanel
class _StatRow extends StatelessWidget {
  final int total;
  final int expiringSoon;

  const _StatRow({required this.total, required this.expiringSoon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(
          icon: Icons.inventory_2_outlined,
          label: '$total продуктов',
          color: AppTokens.textLight,
          background: AppTokens.surfaceVariant,
        ),
        if (expiringSoon > 0) ...[] else const SizedBox.shrink(),
        if (expiringSoon > 0) ...[
          const SizedBox(width: AppTokens.p8),
          _StatChip(
            icon: Icons.schedule_rounded,
            label: '$expiringSoon скоро',
            color: AppTokens.warn,
            background: AppTokens.warnSoft,
          ),
        ],
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.p12,
        vertical: AppTokens.p8,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTokens.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

/// Горизонтальный скролл с фильтрами по категориям продуктов
class _CategoryFilterBar extends StatelessWidget {
  final _FridgeCategory selected;
  final List<FridgeItem> items;
  final ValueChanged<_FridgeCategory> onChanged;

  const _CategoryFilterBar({
    required this.selected,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Показываем только те категории, в которых есть продукты
    final presentCategories = _FridgeCategory.values.where((cat) {
      if (cat == _FridgeCategory.all) return true;
      if (cat == _FridgeCategory.other) {
        final known = [
          _FridgeCategory.dairy,
          _FridgeCategory.meat,
          _FridgeCategory.veggies,
          _FridgeCategory.grains,
          _FridgeCategory.eggs,
        ];
        return items.any((item) => !known.any((c) => c.matches(item.name)));
      }
      return items.any((item) => cat.matches(item.name));
    }).toList();

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: presentCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTokens.p8),
        itemBuilder: (context, index) {
          final cat = presentCategories[index];
          final isSelected = cat == selected;
          return GestureDetector(
            onTap: () => onChanged(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.p12,
                vertical: AppTokens.p8,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppTokens.primary : AppTokens.surface,
                borderRadius: BorderRadius.circular(AppTokens.pill),
                border: Border.all(
                  color: isSelected ? AppTokens.primary : AppTokens.border,
                ),
              ),
              child: Text(
                cat.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected ? Colors.white : AppTokens.textLight,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PhotoSourceSheet extends StatelessWidget {
  const _PhotoSourceSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(AppTokens.p16),
        decoration: BoxDecoration(
          color: AppTokens.surface,
          borderRadius: BorderRadius.circular(AppTokens.r20),
          border: Border.all(color: AppTokens.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.p16,
                AppTokens.p16,
                AppTokens.p16,
                AppTokens.p8,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.camera_alt_rounded,
                    size: 18,
                    color: AppTokens.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Добавить по фото',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Сделать фото'),
              subtitle: const Text('Снять продукты сейчас'),
              onTap: () => Navigator.pop(context, PhotoSource.camera),
            ),
            Divider(color: AppTokens.border.withValues(alpha: 0.8), height: 1),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Выбрать из галереи'),
              subtitle: const Text('Распознать продукты с готового снимка'),
              onTap: () => Navigator.pop(context, PhotoSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}
