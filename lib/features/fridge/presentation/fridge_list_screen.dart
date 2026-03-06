import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_scaffold.dart';
import 'providers.dart';
import 'widgets/fridge_item_card.dart';
import 'fridge_add_edit_screen.dart';
import 'fridge_photo_review_screen.dart';
import '../domain/fridge_item.dart';
import '../domain/photo_source.dart';
import 'package:animations/animations.dart';

class FridgeListScreen extends ConsumerStatefulWidget {
  const FridgeListScreen({super.key});

  @override
  ConsumerState<FridgeListScreen> createState() => _FridgeListScreenState();
}

class _FridgeListScreenState extends ConsumerState<FridgeListScreen> {
  late final TextEditingController _searchController;
  String _query = '';

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

    return AppScaffold(
      title: 'Мой холодильник',
      actions: [
        _PhotoButton(onTap: _startPhotoImport),
        OpenContainer(
          closedElevation: 0,
          openElevation: 0,
          closedColor: Colors.transparent,
          openColor: AppTokens.background,
          middleColor: Colors.transparent,
          transitionType: ContainerTransitionType.fadeThrough,
          closedBuilder: (context, action) => _AddButton(onTap: action),
          openBuilder: (context, action) => const FridgeAddEditScreen(),
        ),
      ],
      body: Column(
        children: [
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Поиск продукта',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: items.isEmpty
                ? _buildEmptyState()
                : filteredItems.isEmpty
                    ? _buildNoResults()
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                            child: OpenContainer(
                              closedElevation: 0,
                              openElevation: 0,
                              closedColor: Colors.transparent,
                              openColor: AppTokens.background,
                              middleColor: Colors.transparent,
                              transitionType:
                                  ContainerTransitionType.fadeThrough,
                              closedBuilder: (context, action) =>
                                  FridgeItemCard(
                                item: item,
                                onTap: action,
                                onDelete: () => ref
                                    .read(fridgeListProvider.notifier)
                                    .removeItem(item.id),
                              ),
                              openBuilder: (context, action) =>
                                  FridgeAddEditScreen(itemToEdit: item),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  List<FridgeItem> _filterItems(List<FridgeItem> items, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return items;
    }
    return items
        .where((item) => item.name.toLowerCase().contains(normalized))
        .toList();
  }

  Widget _buildDismissBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTokens.warn.withValues(alpha: 0.15),
            AppTokens.warn.withValues(alpha: 0.35),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppTokens.r20),
      ),
      child: const Icon(Icons.delete_outline_rounded, color: AppTokens.warn),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTokens.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTokens.primary.withValues(alpha: 0.05),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTokens.fridgeGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTokens.accent.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: const Center(
                child: Text('🥦', style: TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Холодильник пока пуст',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTokens.text,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Нажми + чтобы добавить первые продукты,\nи мы придумаем из них блюдо!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTokens.textLight,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('🔎', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text(
            'Ничего не найдено',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTokens.text,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Попробуйте другое название продукта',
            style: TextStyle(color: AppTokens.textLight),
          ),
        ],
      ),
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
    final result =
        await ref.read(photoImportStateProvider.notifier).importFromPhoto(source);
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (!mounted) {
      return;
    }

    if (result == null) {
      final state = ref.read(photoImportStateProvider);
      if (state.status == PhotoImportStatus.error &&
          state.errorMessage != null &&
          state.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.errorMessage!)),
        );
      }
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
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: AppTokens.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTokens.primary.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 20),
      ),
    );
  }
}

class _PhotoButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PhotoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTokens.surface.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.camera_alt_rounded,
          color: AppTokens.text,
          size: 18,
        ),
      ),
    );
  }
}

class _PhotoSourceSheet extends StatelessWidget {
  const _PhotoSourceSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.r20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppTokens.textLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 14),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Добавить по фото',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTokens.text,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _PhotoSourceTile(
            icon: Icons.photo_camera_rounded,
            title: 'Сделать фото',
            subtitle: 'Откроется камера',
            onTap: () => Navigator.pop(context, PhotoSource.camera),
          ),
          const SizedBox(height: 8),
          _PhotoSourceTile(
            icon: Icons.photo_library_rounded,
            title: 'Выбрать из галереи',
            subtitle: 'Использовать существующее фото',
            onTap: () => Navigator.pop(context, PhotoSource.gallery),
          ),
        ],
      ),
    );
  }
}

class _PhotoSourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PhotoSourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.r12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppTokens.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTokens.r12),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTokens.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppTokens.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTokens.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTokens.textLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTokens.textLight),
          ],
        ),
      ),
    );
  }
}
