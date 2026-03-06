import 'package:flutter/material.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/units.dart';
import '../../domain/recipe.dart';
import '../../domain/recipe_match.dart';
import 'match_bar.dart';

class RecipeCard extends StatelessWidget {
  final RecipeMatch match;
  final VoidCallback onTap;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  const RecipeCard({
    super.key,
    required this.match,
    required this.onTap,
    this.onRename,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasMissing = match.missingIngredients.isNotEmpty;
    final allGood = !hasMissing;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTokens.surface,
          borderRadius: BorderRadius.circular(AppTokens.r20),
          boxShadow: AppTokens.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Градиентная шапка ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppTokens.p16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTokens.primary.withValues(alpha: 0.08),
                    AppTokens.secondary.withValues(alpha: 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.recipe.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        // Теги — время и категория
                        Row(
                          children: [
                            _MiniTag(
                              icon: Icons.timer_rounded,
                              label: '${match.recipe.timeMin} мин',
                              color: AppTokens.primary,
                            ),
                            if (match.recipe.tags.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              _MiniTag(
                                icon: Icons.label_rounded,
                                label: match.recipe.tags.first,
                                color: AppTokens.secondary,
                              ),
                            ],
                            if (match.recipe.source == RecipeSource.aiSaved) ...[
                              const SizedBox(width: 8),
                              _MiniTag(
                                icon: Icons.smart_toy_rounded,
                                label: 'AI',
                                color: AppTokens.accent,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (match.recipe.isUserEditable &&
                          (onRename != null || onDelete != null))
                        PopupMenuButton<_RecipeAction>(
                          icon: const Icon(Icons.more_vert_rounded, size: 18),
                          itemBuilder: (context) => [
                            if (onRename != null)
                              const PopupMenuItem(
                                value: _RecipeAction.rename,
                                child: Text('Переименовать'),
                              ),
                            if (onDelete != null)
                              const PopupMenuItem(
                                value: _RecipeAction.delete,
                                child: Text('Удалить'),
                              ),
                          ],
                          onSelected: (value) {
                            if (value == _RecipeAction.rename) {
                              onRename?.call();
                            } else if (value == _RecipeAction.delete) {
                              onDelete?.call();
                            }
                          },
                        )
                      else
                        const SizedBox(height: 8),
                      MatchBar(score: match.score),
                    ],
                  ),
                ],
              ),
            ),

            // ── Нижняя часть: совпадение ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppTokens.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Строчка с счётчиком совпадений
                  Row(
                    children: [
                      // Прогресс-кнопки
                      ...List.generate(match.totalCount.clamp(0, 6), (i) {
                        final filled = i < match.matchedCount;
                        return Container(
                          margin: const EdgeInsets.only(right: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled
                                ? AppTokens.accent
                                : AppTokens.textLight.withValues(alpha: 0.25),
                          ),
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        'Совпадение ${match.matchedCount} из ${match.totalCount}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppTokens.text,
                        ),
                      ),
                    ],
                  ),

                  if (allGood) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTokens.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppTokens.r8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 14, color: AppTokens.accent),
                          const SizedBox(width: 5),
                          const Text(
                            'Все продукты есть!',
                            style: TextStyle(
                              color: AppTokens.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.remove_shopping_cart_outlined,
                            size: 14, color: AppTokens.warn),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Не хватает: ${_formatMissing()}',
                            style: const TextStyle(
                              color: AppTokens.warn,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMissing() {
    return match.missingIngredients
        .map(
          (e) =>
              '${e.ingredient.name.toLowerCase()} ${_fmtNum(e.missingAmount)} ${e.ingredient.unit.label}',
        )
        .join(', ');
  }

  static String _fmtNum(double v) => v <= 0
      ? '0'
      : v.truncateToDouble() == v
          ? v.toStringAsFixed(0)
          : v.toStringAsFixed(1);
}

enum _RecipeAction { rename, delete }

// ── Мини-тег для времени / тега ─────────────────────────────────────────────

class _MiniTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTokens.r8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
