import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum AppIconButtonTone { neutral, primary, secondary, accent }

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final AppIconButtonTone tone;
  final double size;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.tone = AppIconButtonTone.neutral,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _tonePalette(tone);
    final button = Material(
      color: onPressed == null ? AppTokens.colors.surfaceVariant : palette.$1,
      borderRadius: BorderRadius.circular(AppTokens.radius.md),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTokens.radius.md),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radius.md),
            border: Border.all(color: palette.$2),
          ),
          child: Icon(
            icon,
            color: onPressed == null ? AppTokens.colors.textMuted : palette.$3,
            size: 20,
          ),
        ),
      ),
    );

    if (tooltip == null || tooltip!.isEmpty) {
      return button;
    }
    return Tooltip(message: tooltip!, child: button);
  }

  (Color, Color, Color) _tonePalette(AppIconButtonTone tone) {
    switch (tone) {
      case AppIconButtonTone.primary:
        return (
          AppTokens.colors.primary,
          AppTokens.colors.primary,
          Colors.white,
        );
      case AppIconButtonTone.secondary:
        return (
          AppTokens.colors.secondarySoft,
          Colors.transparent,
          AppTokens.colors.secondaryDark,
        );
      case AppIconButtonTone.accent:
        return (
          AppTokens.colors.accentSoft,
          Colors.transparent,
          AppTokens.colors.accent,
        );
      case AppIconButtonTone.neutral:
        return (
          AppTokens.colors.surface,
          AppTokens.colors.border,
          AppTokens.colors.text,
        );
    }
  }
}
