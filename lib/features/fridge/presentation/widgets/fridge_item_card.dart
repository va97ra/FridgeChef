import 'package:flutter/material.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/units.dart';
import '../../domain/fridge_item.dart';

class FridgeItemCard extends StatelessWidget {
  final FridgeItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const FridgeItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = item.expiresAt != null &&
        item.expiresAt!
            .isBefore(DateTime.now().subtract(const Duration(days: 1)));
    final expiresText = item.expiresAt != null
        ? '${isExpired ? 'Просрочен: ' : 'До: '}${Formatters.formatDate(item.expiresAt!)}'
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTokens.surface,
          borderRadius: BorderRadius.circular(AppTokens.r20),
          boxShadow: AppTokens.cardShadow,
          border: isExpired
              ? Border.all(
                  color: AppTokens.warn.withValues(alpha: 0.40), width: 1.5)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.p16),
          child: Row(
            children: [
              // Иконка
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: isExpired
                      ? LinearGradient(
                          colors: [
                            AppTokens.warn.withValues(alpha: 0.20),
                            AppTokens.warn.withValues(alpha: 0.12),
                          ],
                        )
                      : AppTokens.fridgeGradient,
                  borderRadius: BorderRadius.circular(AppTokens.r16),
                ),
                child: Center(
                  child: Text(
                    _emojiFor(item.name),
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Текст
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        // Количество
                        _Pill(
                          text: '${_fmtNum(item.amount)} ${item.unit.label}',
                          color: AppTokens.primary,
                        ),
                        if (item.calories != null) ...[
                          const SizedBox(width: 6),
                          _Pill(
                            text: '${item.calories} ккал',
                            color: AppTokens.secondary,
                          ),
                        ],
                      ],
                    ),
                    if (expiresText != null) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            isExpired
                                ? Icons.warning_amber_rounded
                                : Icons.schedule_rounded,
                            size: 12,
                            color: isExpired
                                ? AppTokens.warn
                                : AppTokens.textLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            expiresText,
                            style: TextStyle(
                              fontSize: 11,
                              color: isExpired
                                  ? AppTokens.warn
                                  : AppTokens.textLight,
                              fontWeight:
                                  isExpired ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Удалить
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTokens.warn.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppTokens.warn,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmtNum(double v) =>
      v.truncateToDouble() == v ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  /// Примитивный матч названия → эмодзи
  static String _emojiFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('яйц') || n.contains('egg')) return '🥚';
    if (n.contains('молок') || n.contains('milk')) return '🥛';
    if (n.contains('масл') || n.contains('butter')) return '🧈';
    if (n.contains('сыр') || n.contains('cheese')) return '🧀';
    if (n.contains('курин') || n.contains('chicken')) return '🍗';
    if (n.contains('томат') || n.contains('помидор')) return '🍅';
    if (n.contains('огурец') || n.contains('огурц')) return '🥒';
    if (n.contains('лук') || n.contains('onion')) return '🧅';
    if (n.contains('чеснок') || n.contains('garlic')) return '🧄';
    if (n.contains('морков') || n.contains('carrot')) return '🥕';
    if (n.contains('картош') || n.contains('картофел')) return '🥔';
    if (n.contains('мяс') || n.contains('говяд') || n.contains('свинин')) {
      return '🥩';
    }
    if (n.contains('рыб') || n.contains('fish')) return '🐟';
    if (n.contains('хлеб') || n.contains('bread')) return '🍞';
    if (n.contains('рис') || n.contains('rice')) return '🍚';
    if (n.contains('паст') || n.contains('макарон')) return '🍝';
    if (n.contains('гречк')) return '🌾';
    if (n.contains('творог')) return '🧁';
    if (n.contains('сметан')) return '🥣';
    if (n.contains('сахар') || n.contains('sugar')) return '🍬';
    if (n.contains('соль') || n.contains('salt')) return '🧂';
    return '🥗';
  }
}

// ── Pill ─────────────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTokens.r8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
