import 'package:flutter/material.dart';

class AppTokens {
  // ── Brand Palette ──────────────────────────────────────────────────────────
  static const primary = Color(0xFFFF5A5A); // живой красно-оранжевый
  static const primaryLight = Color(0xFFFF8A8A);
  static const primaryDark = Color(0xFFE03A3A);

  static const secondary = Color(0xFFFFB703); // тёплый янтарь
  static const secondaryLight = Color(0xFFFFCF56);
  static const secondaryDark = Color(0xFFF59E00);

  static const accent = Color(0xFF06D6A0); // мятный акцент

  // ── Neutrals ───────────────────────────────────────────────────────────────
  static const background = Color(0xFFF7F3FF); // лавандовый оттенок
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF2EEF9); // чуть насыщеннее

  // ── Text ───────────────────────────────────────────────────────────────────
  static const text = Color(0xFF1E1B2E); // почти чёрный фиолетовый
  static const textLight = Color(0xFF9B93B5); // сиренево-серый
  static const warn = Color(0xFFEF233C);

  // ── Gradient Presets ───────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF5A5A), Color(0xFFFF9A5C)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient primaryGradientV = LinearGradient(
    colors: [Color(0xFFFF5A5A), Color(0xFFFF8A8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFFFDF6FF), Color(0xFFF0F4FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient fridgeGradient = LinearGradient(
    colors: [Color(0xFF4ECDC4), Color(0xFF44B89F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shelfGradient = LinearGradient(
    colors: [Color(0xFFFFB703), Color(0xFFFF8500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Radiuses ───────────────────────────────────────────────────────────────
  static const double r8 = 8.0;
  static const double r12 = 12.0;
  static const double r16 = 16.0;
  static const double r20 = 20.0;
  static const double r24 = 24.0;
  static const double r32 = 32.0;

  // ── Spacing ────────────────────────────────────────────────────────────────
  static const double p4 = 4.0;
  static const double p8 = 8.0;
  static const double p12 = 12.0;
  static const double p16 = 16.0;
  static const double p20 = 20.0;
  static const double p24 = 24.0;
  static const double p32 = 32.0;

  // ── Shadows ────────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF6B5B95).withValues(alpha: 0.10),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get primaryGlowShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.40),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get accentGlowShadow => [
        BoxShadow(
          color: accent.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
}
