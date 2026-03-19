import 'package:flutter/material.dart';

const _cardTextureAsset = 'assets/images/card_board_texture.png';

class RecipeBoardSurface extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final Color accentColor;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final bool showHandle;
  final double textureOpacity;

  const RecipeBoardSurface({
    super.key,
    required this.child,
    required this.gradient,
    required this.accentColor,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.showHandle = true,
    this.textureOpacity = 0.22,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedRadius = borderRadius.resolve(Directionality.of(context));

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        image: DecorationImage(
          image: const AssetImage(_cardTextureAsset),
          fit: BoxFit.cover,
          opacity: textureOpacity,
          filterQuality: FilterQuality.high,
        ),
        borderRadius: resolvedRadius,
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: accentColor.withValues(alpha: 0.18),
            blurRadius: 22,
            spreadRadius: -3,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: resolvedRadius,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.18),
                    ],
                    stops: const [0, 0.24, 1],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: resolvedRadius,
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.08),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.1),
                      ],
                      stops: const [0, 0.16, 1],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            ),
            if (showHandle)
              Positioned(
                top: 16,
                right: 22,
                child: Container(
                  width: 30,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 14,
              left: 20,
              right: showHandle ? 78 : 22,
              child: Transform.rotate(
                angle: -0.05,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
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
              top: 52,
              left: 24,
              right: 104,
              child: Transform.rotate(
                angle: 0.03,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 8,
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0),
                      Colors.black.withValues(alpha: 0.18),
                      Colors.black.withValues(alpha: 0.34),
                    ],
                    stops: const [0, 0.34, 1],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 21,
              child: IgnorePointer(
                child: Container(
                  height: 1.3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -28,
              right: -12,
              child: IgnorePointer(
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -18,
              bottom: -32,
              child: IgnorePointer(
                child: Container(
                  width: 140,
                  height: 92,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(48),
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
            ),
            Padding(
              padding: padding,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class BoardText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Color strokeColor;
  final double strokeWidth;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  const BoardText({
    super.key,
    required this.text,
    required this.style,
    required this.strokeColor,
    this.strokeWidth = 2,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final fillStyle = style.copyWith(
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );

    return CustomPaint(
      painter: _BoardTextStrokePainter(
        text: text,
        style: style,
        strokeColor: strokeColor,
        strokeWidth: strokeWidth,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign ?? TextAlign.start,
        textDirection: Directionality.of(context),
      ),
      child: Text(
        text,
        style: fillStyle,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      ),
    );
  }
}

class _BoardTextStrokePainter extends CustomPainter {
  final String text;
  final TextStyle style;
  final Color strokeColor;
  final double strokeWidth;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign textAlign;
  final TextDirection textDirection;

  const _BoardTextStrokePainter({
    required this.text,
    required this.style,
    required this.strokeColor,
    required this.strokeWidth,
    required this.maxLines,
    required this.overflow,
    required this.textAlign,
    required this.textDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeStyle = style.copyWith(
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = strokeWidth
        ..color = strokeColor,
      shadows: null,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: strokeStyle),
      maxLines: maxLines,
      ellipsis: overflow == TextOverflow.ellipsis ? '\u2026' : null,
      textAlign: textAlign,
      textDirection: textDirection,
    )..layout(maxWidth: size.width.isFinite ? size.width : double.infinity);

    textPainter.paint(canvas, Offset.zero);
  }

  @override
  bool shouldRepaint(covariant _BoardTextStrokePainter oldDelegate) {
    return text != oldDelegate.text ||
        style != oldDelegate.style ||
        strokeColor != oldDelegate.strokeColor ||
        strokeWidth != oldDelegate.strokeWidth ||
        maxLines != oldDelegate.maxLines ||
        overflow != oldDelegate.overflow ||
        textAlign != oldDelegate.textAlign ||
        textDirection != oldDelegate.textDirection;
  }
}
