import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../domain/pantry_catalog_entry.dart';
import '../../domain/shelf_item.dart';

const _cardTextureAsset = 'assets/images/card_board_texture.png';

class ShelfItemChip extends StatelessWidget {
  final ShelfItem item;
  final VoidCallback onToggle;
  final VoidCallback onLongPress;

  const ShelfItemChip({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final background = item.inStock
        ? AppTokens.surfaceRaised
        : AppTokens.surfaceVariant.withValues(alpha: 0.92);
    final border = AppTokens.border;
    final textColor = AppTokens.text;
    final categoryLabel = pantryCategoryLabel(item.category);
    final statusLabel = item.inStock ? 'Есть дома' : 'Нет';
    final statusBackground = item.inStock
        ? AppTokens.surface.withValues(alpha: 0.82)
        : AppTokens.surfaceVariant.withValues(alpha: 0.92);
    final statusColor = item.inStock ? AppTokens.text : AppTokens.textLight;
    final statusDotColor =
        item.inStock ? AppTokens.success : AppTokens.textMuted;

    return InkWell(
      onTap: onToggle,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(AppTokens.r16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          image: const DecorationImage(
            image: AssetImage(_cardTextureAsset),
            fit: BoxFit.cover,
            opacity: 0.34,
            filterQuality: FilterQuality.high,
          ),
          borderRadius: BorderRadius.circular(AppTokens.r16),
          border: Border.all(color: border, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.inStock ? Icons.check_rounded : Icons.add_rounded,
                  size: 16,
                  color: item.inStock ? AppTokens.success : AppTokens.textLight,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: BorderRadius.circular(AppTokens.pill),
                    border: Border.all(color: AppTokens.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusDotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: AppTokens.surfaceRaised.withValues(alpha: 0.84),
                borderRadius: BorderRadius.circular(AppTokens.pill),
                border: Border.all(color: AppTokens.border),
              ),
              child: Text(
                categoryLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTokens.textLight,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
