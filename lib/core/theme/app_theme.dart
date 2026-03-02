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
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: GoogleFonts.nunito(
          color: AppTokens.text,
        ),
        titleLarge: GoogleFonts.nunito(
          color: AppTokens.text,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: GoogleFonts.nunito(
          color: AppTokens.text,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.r12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.r12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.r12),
          borderSide: const BorderSide(color: AppTokens.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.p16,
          vertical: AppTokens.p16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTokens.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.r16),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppTokens.p16),
          elevation: 0,
        ),
      ),
      cardTheme: CardTheme(
        color: AppTokens.surface,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r16),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
