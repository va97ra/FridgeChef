import 'package:flutter/material.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/shelf_item.dart';

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
    return GestureDetector(
      onTap: onToggle,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: item.inStock ? AppTokens.shelfGradient : null,
          color: item.inStock ? null : AppTokens.surface,
          borderRadius: BorderRadius.circular(AppTokens.r20),
          border: Border.all(
            color: item.inStock
                ? Colors.transparent
                : AppTokens.textLight.withValues(alpha: 0.25),
          ),
          boxShadow: item.inStock
              ? [
                  BoxShadow(
                    color: AppTokens.secondary.withValues(alpha: 0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.inStock) ...[
              const Icon(Icons.check_rounded, size: 14, color: Colors.white),
              const SizedBox(width: 5),
            ],
            Text(
              item.name,
              style: TextStyle(
                color: item.inStock ? Colors.white : AppTokens.text,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
