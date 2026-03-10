import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/tokens.dart';

class HomeActionButton extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final LinearGradient gradient;
  final VoidCallback onTap;
  final bool isPrimary;
  final String? metaLabel;
  final String? semanticLabel;

  const HomeActionButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.gradient,
    required this.onTap,
    this.isPrimary = false,
    this.metaLabel,
    this.semanticLabel,
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
      duration: const Duration(milliseconds: 110),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.975).animate(
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
    final semanticLabel = widget.semanticLabel ?? _buildSemanticLabel();

    return Semantics(
      button: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: _CardBody(
              gradient: widget.gradient,
              isPrimary: widget.isPrimary,
              accentColor: widget.accentColor,
              icon: widget.icon,
              title: widget.title,
              subtitle: widget.subtitle,
              metaLabel: widget.metaLabel,
            ),
          ),
        ),
      ),
    );
  }

  String _buildSemanticLabel() {
    final meta = (widget.metaLabel ?? '').trim();
    if (meta.isEmpty) {
      return '${widget.title}. ${widget.subtitle}';
    }
    return '${widget.title}. $meta. ${widget.subtitle}';
  }
}

class _CardBody extends StatelessWidget {
  final LinearGradient gradient;
  final bool isPrimary;
  final Color accentColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? metaLabel;

  const _CardBody({
    required this.gradient,
    required this.isPrimary,
    required this.accentColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.metaLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 130),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppTokens.r24),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isPrimary ? 0.22 : 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Декоративный круг-подсветка в правом верхнем углу
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTokens.p20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Иконка — крупная, белая, полупрозрачный фон
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppTokens.r20),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: isPrimary ? 30 : 28,
                  ),
                ),
                const SizedBox(width: AppTokens.p16),
                // Текст
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: isPrimary ? 19 : 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTokens.p12),
                // Правая часть: счётчик + стрелка
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if ((metaLabel ?? '').isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.p8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(AppTokens.pill),
                        ),
                        child: Text(
                          metaLabel!,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(AppTokens.r12),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
