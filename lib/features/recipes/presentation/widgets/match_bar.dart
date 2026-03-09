import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

class MatchBar extends StatelessWidget {
  final double score;

  const MatchBar({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final clamped = score.clamp(0.0, 1.0);
    final percent = (clamped * 100).round();
    final color = switch (percent) {
      >= 75 => AppTokens.accent,
      >= 45 => AppTokens.secondaryDark,
      _ => AppTokens.primary,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$percent%',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          'совпадение',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 84,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.pill),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: 7,
              backgroundColor: AppTokens.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}
