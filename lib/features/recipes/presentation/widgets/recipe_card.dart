import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../domain/recipe_match.dart';

class RecipeCard extends StatelessWidget {
  final RecipeMatch match;
  final VoidCallback onTap;

  const RecipeCard({
    super.key,
    required this.match,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (match.score * 100).round();
    final hasMissing = match.missingIngredients.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Верхняя часть (заголовок и время)
            Container(
              padding: const EdgeInsets.all(AppTokens.p16),
              color: AppTokens.primary.withOpacity(0.05),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.recipe.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined,
                                size: 16, color: AppTokens.textLight),
                            const SizedBox(width: 4),
                            Text(
                              '${match.recipe.timeMin} мин',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTokens.textLight,
                                  ),
                            ),
                            const SizedBox(width: 12),
                            if (match.recipe.tags.isNotEmpty) ...[
                              const Icon(Icons.local_offer_outlined,
                                  size: 16, color: AppTokens.textLight),
                              const SizedBox(width: 4),
                              Text(
                                match.recipe.tags.first,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppTokens.textLight,
                                    ),
                              ),
                            ]
                          ],
                        ),
                      ],
                    ),
                  ),
                  _MatchBadge(percent: percent),
                ],
              ),
            ),

            // Информация о нехватке продуктов
            Padding(
              padding: const EdgeInsets.all(AppTokens.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Совпадение продуктов: ${match.matchedCount} из ${match.totalCount}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (hasMissing) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Не хватает:',
                      style: TextStyle(
                        color: AppTokens.warn,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      match.missingIngredients
                          .map((e) => e.name.toLowerCase())
                          .join(', '),
                      style:
                          const TextStyle(color: AppTokens.warn, fontSize: 13),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Все продукты есть!',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchBadge extends StatelessWidget {
  final int percent;

  const _MatchBadge({required this.percent});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (percent >= 80) {
      color = Colors.green;
    } else if (percent >= 50) {
      color = AppTokens.secondary;
    } else {
      color = AppTokens.warn;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        '$percent%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
