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
    final boardRadius =
        BorderRadius.circular(isPrimary ? AppTokens.r24 + 2 : AppTokens.r24);
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: isPrimary ? 20 : 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.05,
              letterSpacing: -0.2,
            ) ??
        TextStyle(
          fontSize: isPrimary ? 20 : 18,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1.05,
        );
    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFFF8F2E9),
              fontWeight: FontWeight.w700,
              height: 1.32,
              letterSpacing: 0.05,
            ) ??
        const TextStyle(
          color: Color(0xFFF8F2E9),
          fontWeight: FontWeight.w700,
          fontSize: 12,
          height: 1.32,
        );
    const chipStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w900,
      fontSize: 12,
      letterSpacing: 0.1,
    );

    return Container(
      constraints: BoxConstraints(minHeight: isPrimary ? 142 : 134),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: boardRadius,
        border: Border.all(
          color: Colors.black.withValues(alpha: isPrimary ? 0.2 : 0.16),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isPrimary ? 0.2 : 0.16),
            blurRadius: isPrimary ? 24 : 20,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: accentColor.withValues(alpha: isPrimary ? 0.22 : 0.16),
            blurRadius: 18,
            spreadRadius: -2,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: boardRadius,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.1),
                  ],
                  stops: const [0, 0.28, 1],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            top: 18,
            right: 24,
            child: Container(
              width: 30,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppTokens.pill),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 22,
            right: 82,
            child: Transform.rotate(
              angle: -0.05,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTokens.pill),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: isPrimary ? 56 : 52,
            left: 30,
            right: 108,
            child: Transform.rotate(
              angle: 0.03,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTokens.pill),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.09),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 8,
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.16),
                    Colors.black.withValues(alpha: 0.3),
                  ],
                  stops: const [0, 0.35, 1],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            top: -32,
            right: -18,
            child: Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            left: -14,
            bottom: -30,
            child: Container(
              width: 148,
              height: 92,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(44),
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTokens.p20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.24),
                        Colors.white.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppTokens.r20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: isPrimary ? 30 : 28,
                  ),
                ),
                const SizedBox(width: AppTokens.p16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      if ((metaLabel ?? '').isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.p8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(AppTokens.pill),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: _OutlinedBoardText(
                            text: metaLabel!,
                            style: chipStyle,
                            strokeColor: Colors.black.withValues(alpha: 0.22),
                            strokeWidth: 2,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      _OutlinedBoardText(
                        text: title,
                        style: titleStyle,
                        strokeColor: Colors.black.withValues(alpha: 0.24),
                        strokeWidth: 2.6,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      _OutlinedBoardText(
                        text: subtitle,
                        style: subtitleStyle,
                        strokeColor: Colors.black.withValues(alpha: 0.18),
                        strokeWidth: 1.8,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTokens.p12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const SizedBox(height: 22),
                    Container(
                      width: isPrimary ? 46 : 42,
                      height: isPrimary ? 46 : 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.24),
                            Colors.white.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppTokens.r16 + 2),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.14),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                        shadows: [
                          Shadow(
                            color: Color(0x44000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
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

class _OutlinedBoardText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Color strokeColor;
  final double strokeWidth;
  final int? maxLines;
  final TextOverflow? overflow;

  const _OutlinedBoardText({
    required this.text,
    required this.style,
    required this.strokeColor,
    required this.strokeWidth,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final strokeStyle = style.copyWith(
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..color = strokeColor,
      shadows: null,
    );
    final fillStyle = style.copyWith(
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: 0.14),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );

    return Stack(
      children: [
        Text(
          text,
          style: strokeStyle,
          maxLines: maxLines,
          overflow: overflow,
        ),
        Text(
          text,
          style: fillStyle,
          maxLines: maxLines,
          overflow: overflow,
        ),
      ],
    );
  }
}
