import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/tokens.dart';
import '../../domain/shelf_item.dart';

class ShelfItemChip extends StatefulWidget {
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
  State<ShelfItemChip> createState() => _ShelfItemChipState();
}

class _ShelfItemChipState extends State<ShelfItemChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final inStock = widget.item.inStock;

    final chipColor = inStock ? AppTokens.accentSoft : AppTokens.surfaceVariant;
    final borderColor =
        inStock ? AppTokens.accent.withValues(alpha: 0.55) : AppTokens.border;
    final dotColor = inStock ? AppTokens.success : AppTokens.textMuted;
    final textColor = inStock ? AppTokens.text : AppTokens.textLight;

    return Semantics(
      button: true,
      toggled: inStock,
      label:
          '${widget.item.name}. ${inStock ? 'Есть дома. Нажми чтобы убрать' : 'Нет. Нажми чтобы отметить как есть'}. Долгое нажатие — редактировать.',
      child: ExcludeSemantics(
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            HapticFeedback.selectionClick();
            widget.onToggle();
          },
          onTapCancel: () => setState(() => _pressed = false),
          onLongPress: () {
            HapticFeedback.mediumImpact();
            widget.onLongPress();
          },
          child: AnimatedScale(
            scale: _pressed ? 0.94 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: chipColor,
                borderRadius: BorderRadius.circular(AppTokens.r12),
                border: Border.all(
                  color: borderColor,
                  width: inStock ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Цветная точка-индикатор наличия
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    widget.item.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
