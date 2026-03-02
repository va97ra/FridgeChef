import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/tokens.dart';

class HomeActionButton extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;
  final bool isPrimary;

  const HomeActionButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  State<HomeActionButton> createState() => _HomeActionButtonState();
}

class _HomeActionButtonState extends State<HomeActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) => _controller.forward();

  Future<void> _handleTapUp(TapUpDetails _) async {
    await _controller.reverse();
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  void _handleTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: widget.isPrimary ? widget.gradient : null,
            color: widget.isPrimary ? null : AppTokens.surface,
            borderRadius: BorderRadius.circular(AppTokens.r24),
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                      color: AppTokens.primary.withValues(alpha: 0.38),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : AppTokens.cardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.r24),
            child: Stack(
              children: [
                // Декоративный кружок в правом нижнем углу только для primary
                if (widget.isPrimary)
                  Positioned(
                    right: -20,
                    bottom: -30,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.p20,
                    vertical: AppTokens.p20,
                  ),
                  child: Row(
                    children: [
                      // Иконка-кружок
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: widget.isPrimary ? null : widget.gradient,
                          color: widget.isPrimary
                              ? Colors.white.withValues(alpha: 0.22)
                              : null,
                          borderRadius: BorderRadius.circular(AppTokens.r16),
                          boxShadow: widget.isPrimary
                              ? null
                              : [
                                  BoxShadow(
                                    color: _gradientFirstColor(widget.gradient)
                                        .withValues(alpha: 0.30),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Icon(
                          widget.icon,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: AppTokens.p16),
                      // Тексты
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: widget.isPrimary
                                        ? Colors.white
                                        : AppTokens.text,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.subtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: widget.isPrimary
                                        ? Colors.white.withValues(alpha: 0.78)
                                        : AppTokens.textLight,
                                    fontSize: 13,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      // Стрелочка
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: widget.isPrimary
                              ? Colors.white.withValues(alpha: 0.20)
                              : AppTokens.background,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: widget.isPrimary
                              ? Colors.white
                              : AppTokens.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Color _gradientFirstColor(Gradient g) {
    if (g is LinearGradient && g.colors.isNotEmpty) return g.colors.first;
    return Colors.grey;
  }
}
