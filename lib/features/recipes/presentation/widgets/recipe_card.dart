import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/units.dart';
import '../../domain/recipe.dart';
import '../../domain/recipe_match.dart';
import '../../domain/recipe_nutrition.dart';
import '../recipe_ui_meta.dart';
import 'match_bar.dart';
import 'recipe_board_surface.dart';

class RecipeCard extends StatelessWidget {
  final RecipeMatch match;
  final RecipeNutritionEstimate? nutritionEstimate;
  final VoidCallback onTap;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  const RecipeCard({
    super.key,
    required this.match,
    this.nutritionEstimate,
    required this.onTap,
    this.onRename,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasMissing = match.missingIngredients.isNotEmpty;
    final moodBadges = buildRecipeMoodBadges(match.recipe);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;
        final reasonMaxWidth = compact ? constraints.maxWidth - 32 : 220.0;

        return Semantics(
          button: true,
          container: true,
          label: _semanticLabel,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTokens.r20),
            child: RecipeBoardSurface(
              gradient: AppTokens.recipeBoardGradient,
              accentColor: hasMissing ? AppTokens.warn : _sourceColor,
              showHandle: false,
              padding: const EdgeInsets.all(AppTokens.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MiniTag(
                              icon: _sourceIcon,
                              label: _sourceLabel,
                              color: _sourceColor,
                              background: _sourceBackground,
                              borderColor: Colors.transparent,
                            ),
                            _MiniTag(
                              icon: Icons.timer_outlined,
                              label: '${match.recipe.timeMin} мин',
                              color: AppTokens.text,
                              background: AppTokens.insetSurface,
                              borderColor: AppTokens.insetBorder,
                            ),
                            if (nutritionEstimate?.hasData ?? false)
                              _MiniTag(
                                icon: Icons.local_fire_department_outlined,
                                label:
                                    '~${nutritionEstimate!.total.calories.round()} ккал',
                                color: AppTokens.warn,
                                background: AppTokens.warnSoft,
                                borderColor: AppTokens.insetBorder,
                              ),
                            for (final badge in moodBadges.take(3))
                              _MiniTag(
                                icon: _iconForBadge(badge),
                                label: badge,
                                color: AppTokens.secondaryDark,
                                background: AppTokens.secondarySoft,
                                borderColor: AppTokens.insetBorder,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (match.recipe.isUserEditable &&
                          (onRename != null || onDelete != null))
                        PopupMenuButton<_RecipeAction>(
                          tooltip: 'Действия рецепта ${match.recipe.title}',
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
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.p12),
                  if (compact) ...[
                    _CardMainContent(
                      match: match,
                      reasonMaxWidth: reasonMaxWidth,
                    ),
                    const SizedBox(height: AppTokens.p12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: MatchBar(score: match.score),
                    ),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _CardMainContent(
                            match: match,
                            reasonMaxWidth: reasonMaxWidth,
                          ),
                        ),
                        const SizedBox(width: AppTokens.p12),
                        MatchBar(score: match.score),
                      ],
                    ),
                  const SizedBox(height: AppTokens.p16),
                  Container(
                    padding: const EdgeInsets.all(AppTokens.p12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTokens.r16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Совпадение ${match.matchedCount} из ${match.totalCount}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hasMissing
                                    ? 'Нужно: ${_formatMissing()}'
                                    : 'Все нужные продукты уже есть дома',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: hasMissing
                                          ? const Color(0xFFFFC4A3)
                                          : const Color(0xFFE4F2D9),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppTokens.p12),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData get _sourceIcon {
    if (match.source == RecipeMatchSource.generated) {
      return Icons.lightbulb_outline_rounded;
    }
    if (match.recipe.source == RecipeSource.generatedSaved) {
      return Icons.bookmark_added_outlined;
    }
    return Icons.menu_book_outlined;
  }

  String get _sourceLabel {
    if (match.source == RecipeMatchSource.generated) {
      return 'Шеф-идея';
    }
    if (match.recipe.source == RecipeSource.generatedSaved) {
      return 'Сохранён';
    }
    return 'База';
  }

  Color get _sourceColor {
    if (match.source == RecipeMatchSource.generated) {
      return AppTokens.accent;
    }
    if (match.recipe.source == RecipeSource.generatedSaved) {
      return AppTokens.secondaryDark;
    }
    return AppTokens.primary;
  }

  Color get _sourceBackground {
    if (match.source == RecipeMatchSource.generated) {
      return AppTokens.accentSoft;
    }
    if (match.recipe.source == RecipeSource.generatedSaved) {
      return AppTokens.secondarySoft;
    }
    return AppTokens.primarySoft;
  }

  String _formatMissing() {
    return match.missingIngredients
        .map(
          (e) =>
              '${e.ingredient.name.toLowerCase()} ${_fmtNum(e.missingAmount)} ${e.ingredient.unit.label}',
        )
        .join(', ');
  }

  String get _semanticLabel {
    final availability = match.missingIngredients.isEmpty
        ? 'Все нужные продукты уже есть дома'
        : 'Нужно: ${_formatMissing()}';
    return 'Открыть рецепт ${match.recipe.title}. '
        '${match.recipe.timeMin} минут. '
        '$_sourceLabel. '
        'Совпадение ${match.matchedCount} из ${match.totalCount}. '
        '$availability';
  }

  static String _fmtNum(double v) => v <= 0
      ? '0'
      : v.truncateToDouble() == v
          ? v.toStringAsFixed(0)
          : v.toStringAsFixed(1);
}

IconData _iconForBadge(String label) {
  switch (label) {
    case 'Завтрак':
      return Icons.wb_sunny_outlined;
    case 'Детям':
      return Icons.child_care_outlined;
    case 'Легко':
      return Icons.flash_on_outlined;
    case 'Сытно':
      return Icons.dinner_dining_outlined;
    case 'Ужин':
      return Icons.nightlight_outlined;
    case 'Одна сковорода':
      return Icons.lunch_dining_outlined;
    default:
      return Icons.label_outline_rounded;
  }
}

enum _RecipeAction { rename, delete }

class _CardMainContent extends StatelessWidget {
  final RecipeMatch match;
  final double reasonMaxWidth;

  const _CardMainContent({
    required this.match,
    required this.reasonMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BoardText(
          text: match.recipe.title,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.04,
                  ) ??
              const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.04,
              ),
          strokeColor: Colors.black.withValues(alpha: 0.24),
          strokeWidth: 2.3,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (match.why.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: match.why.take(2).map((reason) {
              return _ReasonTag(
                label: reason,
                maxWidth: reasonMaxWidth,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _MiniTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final Color borderColor;

  const _MiniTag({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: background.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppTokens.pill),
        border: Border.all(
          color: borderColor == Colors.transparent
              ? Colors.white.withValues(alpha: 0.14)
              : borderColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _ReasonTag extends StatelessWidget {
  final String label;
  final double maxWidth;

  const _ReasonTag({
    required this.label,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTokens.pill),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome_outlined,
              size: 13,
              color: Colors.white,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
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
