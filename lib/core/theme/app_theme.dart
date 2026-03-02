import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppTokens.background,
      colorScheme: const ColorScheme.light(
        primary: AppTokens.primary,
        secondary: AppTokens.secondary,
        surface: AppTokens.surface,
        error: AppTokens.warn,
        onPrimary: Colors.white,
        onSecondary: AppTokens.text,
        onSurface: AppTokens.text,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.nunitoTextTheme().copyWith(
        displayLarge: GoogleFonts.nunito(
          color: AppTokens.text,
          fontWeight: FontWeight.w900,
          fontSize: 36,
          height: 1.15,
        ),
        displayMedium: GoogleFonts.nunito(
          color: AppTokens.text,
          fontWeight: FontWeight.w800,
          fontSize: 28,
        ),
        headlineLarge: GoogleFonts.nunito(
          color: AppTokens.text,
          fontWeight: FontWeight.w800,
          fontSize: 24,
        ),
        titleLarge: GoogleFonts.nunito(
          color: AppTokens.text,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
        titleMedium: GoogleFonts.nunito(
          color: AppTokens.text,
          fontWeight: FontWeight.w700,
          fontSize: 16,
          letterSpacing: 0.1,
        ),
        bodyLarge: GoogleFonts.nunito(
          color: AppTokens.text,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: GoogleFonts.nunito(
          color: AppTokens.textLight,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodySmall: GoogleFonts.nunito(
          color: AppTokens.textLight,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelLarge: GoogleFonts.nunito(
          color: AppTokens.text,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.r16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.r16),
          borderSide: BorderSide(
            color: AppTokens.textLight.withValues(alpha: 0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.r16),
          borderSide: const BorderSide(color: AppTokens.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.p20,
          vertical: AppTokens.p16,
        ),
        hintStyle: GoogleFonts.nunito(
          color: AppTokens.textLight,
          fontWeight: FontWeight.w500,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTokens.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.r20),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppTokens.p16),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppTokens.surfaceVariant,
        selectedColor: AppTokens.primary.withValues(alpha: 0.15),
        labelStyle: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTokens.text,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r12),
        ),
        side: BorderSide(color: AppTokens.textLight.withValues(alpha: 0.2)),
        padding:
            const EdgeInsets.symmetric(horizontal: AppTokens.p12, vertical: 6),
      ),
      cardTheme: CardThemeData(
        color: AppTokens.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r20),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.nunito(
          color: AppTokens.text,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
        iconTheme: const IconThemeData(color: AppTokens.text),
      ),
    );
  }
}
