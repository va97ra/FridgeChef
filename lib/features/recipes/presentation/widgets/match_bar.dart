import 'package:flutter/material.dart';
import '../../../../core/theme/tokens.dart';

class MatchBar extends StatelessWidget {
  final double score;

  const MatchBar({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final clamped = score.clamp(0.0, 1.0);
    final percent = (clamped * 100).round();

    final Gradient gradient;
    if (percent >= 80) {
      gradient =
          const LinearGradient(colors: [Color(0xFF06D6A0), Color(0xFF00B383)]);
    } else if (percent >= 50) {
      gradient =
          const LinearGradient(colors: [Color(0xFFFFB703), Color(0xFFFF8500)]);
    } else {
      gradient =
          const LinearGradient(colors: [Color(0xFFFF5A5A), Color(0xFFFF8A8A)]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Процент крупно
        ShaderMask(
          shaderCallback: (bounds) => gradient.createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: Text(
            '$percent%',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'совпадение',
          style: TextStyle(
            color: AppTokens.textLight,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        // Прогресс-бар
        SizedBox(
          width: 80,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.r12),
            child: Container(
              height: 6,
              color: AppTokens.textLight.withValues(alpha: 0.15),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: clamped,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(AppTokens.r12),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
