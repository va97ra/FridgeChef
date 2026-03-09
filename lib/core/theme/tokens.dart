import 'package:flutter/material.dart';

class AppTokens {
  static const colors = AppColorRefs();
  static const spacing = AppSpacingRefs();
  static const radius = AppRadiusRefs();
  static const elevation = AppElevationRefs();
  static const gradients = AppGradientRefs();

  static const background = Color(0xFFF6F2EA);
  static const backgroundAlt = Color(0xFFEEE7DA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceRaised = Color(0xFFFCF9F3);
  static const surfaceVariant = Color(0xFFF1ECE2);
  static const insetSurface = Color(0xFFF7EFE3);
  static const insetSurfaceStrong = Color(0xFFF0E2CF);
  static const insetBorder = Color(0xFFD9C8AE);
  static const border = Color(0xFFD2C0A9);
  static const outlineStrong = Color(0xFFB69E7E);

  static const text = Color(0xFF1E1A16);
  static const textLight = Color(0xFF5F5448);
  static const textMuted = Color(0xFF817362);

  static const primary = Color(0xFFD6673F);
  static const primaryLight = Color(0xFFE79A76);
  static const primaryDark = Color(0xFFB9512D);
  static const primarySoft = Color(0xFFF6DED4);

  static const secondary = Color(0xFFC0942E);
  static const secondaryLight = Color(0xFFD9B15B);
  static const secondaryDark = Color(0xFF9B7623);
  static const secondarySoft = Color(0xFFF6E8C8);

  static const accent = Color(0xFF4E7A5A);
  static const accentSoft = Color(0xFFDCE8DF);
  static const success = Color(0xFF2F8E5C);
  static const successSoft = Color(0xFFD9EADF);

  static const warn = Color(0xFFC44C34);
  static const warnSoft = Color(0xFFF5DDD7);
  static const info = Color(0xFF5D6E92);
  static const infoSoft = Color(0xFFDDE4F1);

  static const primaryGradient = LinearGradient(
    colors: [Color(0xFFD6673F), Color(0xFFE58F62)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const primaryGradientV = LinearGradient(
    colors: [Color(0xFFD6673F), Color(0xFFC45A35)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const bgGradient = LinearGradient(
    colors: [Color(0xFFF9F5EE), Color(0xFFF2ECE3)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const fridgeGradient = LinearGradient(
    colors: [Color(0xFF5F8B69), Color(0xFF4E7A5A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const shelfGradient = LinearGradient(
    colors: [Color(0xFFC0942E), Color(0xFFD1A84A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const r8 = 10.0;
  static const r12 = 14.0;
  static const r16 = 18.0;
  static const r20 = 22.0;
  static const r24 = 26.0;
  static const r32 = 32.0;
  static const pill = 999.0;

  static const p4 = 4.0;
  static const p8 = 8.0;
  static const p12 = 12.0;
  static const p16 = 16.0;
  static const p20 = 20.0;
  static const p24 = 24.0;
  static const p32 = 32.0;

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get primaryGlowShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.14),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get accentGlowShadow => [
        BoxShadow(
          color: accent.withValues(alpha: 0.12),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];
}

class AppColorRefs {
  const AppColorRefs();

  Color get background => AppTokens.background;
  Color get backgroundAlt => AppTokens.backgroundAlt;
  Color get surface => AppTokens.surface;
  Color get surfaceRaised => AppTokens.surfaceRaised;
  Color get surfaceVariant => AppTokens.surfaceVariant;
  Color get insetSurface => AppTokens.insetSurface;
  Color get insetSurfaceStrong => AppTokens.insetSurfaceStrong;
  Color get insetBorder => AppTokens.insetBorder;
  Color get border => AppTokens.border;
  Color get outlineStrong => AppTokens.outlineStrong;
  Color get text => AppTokens.text;
  Color get textLight => AppTokens.textLight;
  Color get textMuted => AppTokens.textMuted;
  Color get primary => AppTokens.primary;
  Color get primaryLight => AppTokens.primaryLight;
  Color get primaryDark => AppTokens.primaryDark;
  Color get primarySoft => AppTokens.primarySoft;
  Color get secondary => AppTokens.secondary;
  Color get secondaryLight => AppTokens.secondaryLight;
  Color get secondaryDark => AppTokens.secondaryDark;
  Color get secondarySoft => AppTokens.secondarySoft;
  Color get accent => AppTokens.accent;
  Color get accentSoft => AppTokens.accentSoft;
  Color get success => AppTokens.success;
  Color get successSoft => AppTokens.successSoft;
  Color get warn => AppTokens.warn;
  Color get warnSoft => AppTokens.warnSoft;
  Color get info => AppTokens.info;
  Color get infoSoft => AppTokens.infoSoft;
}

class AppSpacingRefs {
  const AppSpacingRefs();

  double get xs => AppTokens.p4;
  double get sm => AppTokens.p8;
  double get md => AppTokens.p12;
  double get lg => AppTokens.p16;
  double get xl => AppTokens.p20;
  double get xxl => AppTokens.p24;
  double get display => AppTokens.p32;
}

class AppRadiusRefs {
  const AppRadiusRefs();

  double get sm => AppTokens.r8;
  double get md => AppTokens.r12;
  double get lg => AppTokens.r16;
  double get xl => AppTokens.r20;
  double get xxl => AppTokens.r24;
  double get display => AppTokens.r32;
  double get pill => AppTokens.pill;
}

class AppElevationRefs {
  const AppElevationRefs();

  double get low => 0;
  double get medium => 1;
  double get high => 2;
}

class AppGradientRefs {
  const AppGradientRefs();

  Gradient get primary => AppTokens.primaryGradient;
  Gradient get primaryVertical => AppTokens.primaryGradientV;
  Gradient get background => AppTokens.bgGradient;
  Gradient get fridge => AppTokens.fridgeGradient;
  Gradient get shelf => AppTokens.shelfGradient;
}
