import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum SectionSurfaceTone { base, muted, primarySoft, accentSoft, warnSoft }

const _cardTextureAsset = 'assets/images/card_board_texture.png';

class SectionSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final SectionSurfaceTone tone;
  final bool withShadow;

  const SectionSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTokens.p16),
    this.tone = SectionSurfaceTone.base,
    this.withShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      SectionSurfaceTone.base => AppTokens.colors.surface,
      SectionSurfaceTone.muted => AppTokens.colors.surfaceRaised,
      SectionSurfaceTone.primarySoft => AppTokens.colors.primarySoft,
      SectionSurfaceTone.accentSoft => AppTokens.colors.accentSoft,
      SectionSurfaceTone.warnSoft => AppTokens.colors.warnSoft,
    };
    final textureOpacity = switch (tone) {
      SectionSurfaceTone.base => 0.26,
      SectionSurfaceTone.muted => 0.24,
      SectionSurfaceTone.primarySoft => 0.18,
      SectionSurfaceTone.accentSoft => 0.18,
      SectionSurfaceTone.warnSoft => 0.18,
    };

    return Container(
      decoration: BoxDecoration(
        color: color,
        image: DecorationImage(
          image: const AssetImage(_cardTextureAsset),
          fit: BoxFit.cover,
          opacity: textureOpacity,
          filterQuality: FilterQuality.high,
        ),
        borderRadius: BorderRadius.circular(AppTokens.radius.xl),
        border: Border.all(color: AppTokens.colors.border),
        boxShadow: withShadow ? AppTokens.cardShadow : const [],
      ),
      padding: padding,
      child: child,
    );
  }
}
