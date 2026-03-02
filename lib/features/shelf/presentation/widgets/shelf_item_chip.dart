import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../domain/shelf_item.dart';

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
      onLongPress: onLongPress,
      child: FilterChip(
        label: Text(item.name),
        selected: item.inStock,
        onSelected: (_) => onToggle(),
        selectedColor: AppTokens.secondary.withOpacity(0.3),
        checkmarkColor: AppTokens.text,
        backgroundColor: AppTokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r12),
          side: BorderSide(
            color: item.inStock
                ? AppTokens.secondary
                : AppTokens.textLight.withOpacity(0.2),
          ),
        ),
      ),
    );
  }
}
