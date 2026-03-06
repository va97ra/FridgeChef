import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_scaffold.dart';
import 'providers.dart';
import 'widgets/shelf_item_chip.dart';
import 'shelf_add_edit_screen.dart';

class ShelfListScreen extends ConsumerWidget {
  const ShelfListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(shelfListProvider);
    final inStock = items.where((i) => i.inStock).length;

    return AppScaffold(
      title: 'Полка',
      actions: [
        _AddButton(
          onTap: () => Navigator.push(
            context,
            AppRoutes.fadeThroughRoute(page: const ShelfAddEditScreen()),
          ),
        ),
      ],
      body: items.isEmpty
          ? _buildEmptyState()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Счётчик наличия
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTokens.secondary.withValues(alpha: 0.14),
                        AppTokens.primary.withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTokens.r16),
                  ),
                  child: Row(
                    children: [
                      const Text('🧂', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Text(
                        'В наличии: $inStock из ${items.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTokens.text,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Отметьте, что у вас есть:',
                  style: TextStyle(
                    color: AppTokens.textLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: items.map((item) {
                        return ShelfItemChip(
                          item: item,
                          onToggle: () => ref
                              .read(shelfListProvider.notifier)
                              .toggleItem(item),
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
                  ),
                ),
              ],
            ),
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
              color: AppTokens.secondary.withValues(alpha: 0.05),
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
                gradient: AppTokens.shelfGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTokens.secondary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: const Center(
                child: Text('🧂', style: TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Полка абсолютно пуста',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTokens.text,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Добавь специи, масла и соусы через +,\nчтобы рецепты получались точнее',
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
          gradient: AppTokens.shelfGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTokens.secondary.withValues(alpha: 0.35),
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
