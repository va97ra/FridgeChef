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
    final visual = _visualFor(item.name);
    final expiryState = _expiryState(item.expiresAt);

    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.r20),
        border: Border.all(
          color: expiryState.$1 ?? AppTokens.border,
        ),
        boxShadow: AppTokens.cardShadow,
      ),
      padding: const EdgeInsets.all(AppTokens.p16),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: _openSemanticLabel(expiryState.$2),
              child: ExcludeSemantics(
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(AppTokens.r20),
                  child: Row(
                    children: [
                      // Аватар-иконка продукта
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: visual.$2,
                          borderRadius: BorderRadius.circular(AppTokens.r16),
                        ),
                        child: Icon(visual.$1, color: visual.$3, size: 26),
                      ),
                      const SizedBox(width: AppTokens.p16),
                      // Информация о продукте
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                                if (expiryState.$2 != null) ...[
                                  const SizedBox(width: 8),
                                  _TinyBadge(
                                    text: expiryState.$2!,
                                    color: expiryState.$3!,
                                    background: expiryState.$4!,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _TinyBadge(
                                  text:
                                      '${_fmtNum(item.amount)} ${item.unit.label}',
                                  color: AppTokens.text,
                                  background: AppTokens.surfaceVariant,
                                ),
                                if (item.calories != null)
                                  _TinyBadge(
                                    text: '${item.calories} ккал',
                                    color: AppTokens.secondaryDark,
                                    background: AppTokens.secondarySoft,
                                  ),
                              ],
                            ),
                            if (item.expiresAt != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 12,
                                    color:
                                        expiryState.$3 ?? AppTokens.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Срок: ${Formatters.formatDate(item.expiresAt!)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: expiryState.$3 ??
                                              AppTokens.textLight,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppTokens.p8),
                      // Стрелка редактирования
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppTokens.textMuted,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTokens.p8),
          Semantics(
            button: true,
            label: 'Удалить продукт ${item.name}',
            child: ExcludeSemantics(
              child: IconButton(
                tooltip: 'Удалить продукт ${item.name}',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppTokens.textMuted,
                ),
                splashRadius: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtNum(double v) =>
      v.truncateToDouble() == v ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  String _openSemanticLabel(String? expiryBadge) {
    final parts = <String>[
      'Открыть продукт ${item.name}',
      'Количество ${_fmtNum(item.amount)} ${item.unit.label}',
      if (item.calories != null) '${item.calories} килокалорий',
      if (item.expiresAt != null)
        'Срок годности ${Formatters.formatDate(item.expiresAt!)}'
      else
        'Срок годности не указан',
      if (expiryBadge != null) 'Статус $expiryBadge',
    ];
    return '${parts.join('. ')}.';
  }

  (Color?, String?, Color?, Color?) _expiryState(DateTime? expiresAt) {
    if (expiresAt == null) {
      return (null, null, null, null);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiresAt.year, expiresAt.month, expiresAt.day);
    final days = expiry.difference(today).inDays;

    if (days < 0) {
      return (
        AppTokens.warn.withValues(alpha: 0.35),
        'Просрочен',
        AppTokens.warn,
        AppTokens.warnSoft,
      );
    }
    if (days <= 2) {
      return (
        AppTokens.secondary.withValues(alpha: 0.35),
        'Скоро',
        AppTokens.secondaryDark,
        AppTokens.secondarySoft,
      );
    }
    return (null, null, null, null);
  }

  (IconData, Color, Color) _visualFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('яйц')) {
      return (
        Icons.egg_alt_outlined,
        AppTokens.secondarySoft,
        AppTokens.secondaryDark
      );
    }
    if (n.contains('молок') || n.contains('кефир') || n.contains('йогурт')) {
      return (Icons.local_drink_outlined, AppTokens.infoSoft, AppTokens.info);
    }
    if (n.contains('сыр') || n.contains('творог') || n.contains('сметан')) {
      return (
        Icons.breakfast_dining_outlined,
        AppTokens.primarySoft,
        AppTokens.primaryDark
      );
    }
    if (n.contains('куриц') ||
        n.contains('фарш') ||
        n.contains('сосиск') ||
        n.contains('мяс')) {
      return (Icons.set_meal_outlined, AppTokens.warnSoft, AppTokens.warn);
    }
    if (n.contains('рис') ||
        n.contains('греч') ||
        n.contains('макарон') ||
        n.contains('кускус') ||
        n.contains('овсян')) {
      return (
        Icons.grain_outlined,
        AppTokens.secondarySoft,
        AppTokens.secondaryDark
      );
    }
    if (n.contains('помид') ||
        n.contains('огур') ||
        n.contains('морков') ||
        n.contains('капуст') ||
        n.contains('кабач') ||
        n.contains('картош') ||
        n.contains('лук') ||
        n.contains('чеснок')) {
      return (Icons.eco_outlined, AppTokens.accentSoft, AppTokens.accent);
    }
    if (n.contains('масл') || n.contains('майонез') || n.contains('соус')) {
      return (
        Icons.opacity_outlined,
        AppTokens.secondarySoft,
        AppTokens.secondaryDark
      );
    }
    if (n.contains('хлеб') || n.contains('батон') || n.contains('лаваш')) {
      return (
        Icons.bakery_dining_outlined,
        AppTokens.primarySoft,
        AppTokens.primaryDark
      );
    }
    return (
      Icons.inventory_2_outlined,
      AppTokens.surfaceVariant,
      AppTokens.textLight
    );
  }
}

class _TinyBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;

  const _TinyBadge({
    required this.text,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTokens.pill),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
