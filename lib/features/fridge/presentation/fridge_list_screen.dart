import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_scaffold.dart';
import 'providers.dart';
import 'widgets/fridge_item_card.dart';
import 'fridge_add_edit_screen.dart';
import '../domain/fridge_item.dart';
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
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🥦', style: TextStyle(fontSize: 56)),
          SizedBox(height: 20),
          Text(
            'Холодильник пуст',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTokens.text,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Нажми + чтобы добавить\nпервый продукт',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTokens.textLight,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
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
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
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
