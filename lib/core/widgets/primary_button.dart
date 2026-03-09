import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

enum PrimaryButtonVariant { primary, secondary, ghost }

class PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final PrimaryButtonVariant variant;
  final double height;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.variant = PrimaryButtonVariant.primary,
    this.height = 52,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.forward();

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    HapticFeedback.lightImpact();
    widget.onPressed();
  }

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(widget.variant);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: palette.$1,
            color: palette.$1 == null ? palette.$2 : null,
            borderRadius: BorderRadius.circular(AppTokens.radius.xl),
            border: Border.all(color: palette.$3),
            boxShadow: palette.$4 ? AppTokens.primaryGlowShadow : const [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: palette.$5, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text,
                style: TextStyle(
                  color: palette.$5,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Gradient?, Color, Color, bool, Color) _paletteFor(
    PrimaryButtonVariant variant,
  ) {
    switch (variant) {
      case PrimaryButtonVariant.secondary:
        return (
          null,
          AppTokens.colors.surface,
          AppTokens.colors.border,
          false,
          AppTokens.colors.text,
        );
      case PrimaryButtonVariant.ghost:
        return (
          null,
          Colors.transparent,
          Colors.transparent,
          false,
          AppTokens.colors.primary,
        );
      case PrimaryButtonVariant.primary:
        return (
          AppTokens.primaryGradient,
          AppTokens.colors.primary,
          Colors.transparent,
          true,
          Colors.white,
        );
    }
  }
}
