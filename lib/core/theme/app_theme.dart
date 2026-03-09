import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.manropeTextTheme().copyWith(
      displayLarge: GoogleFonts.manrope(
        color: AppTokens.text,
        fontWeight: FontWeight.w800,
        fontSize: 34,
        height: 1.08,
        letterSpacing: -0.6,
      ),
      displayMedium: GoogleFonts.manrope(
        color: AppTokens.text,
        fontWeight: FontWeight.w800,
        fontSize: 28,
        height: 1.1,
        letterSpacing: -0.4,
      ),
      headlineLarge: GoogleFonts.manrope(
        color: AppTokens.text,
        fontWeight: FontWeight.w800,
        fontSize: 24,
        height: 1.15,
        letterSpacing: -0.3,
      ),
      titleLarge: GoogleFonts.manrope(
        color: AppTokens.text,
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
      titleMedium: GoogleFonts.manrope(
        color: AppTokens.text,
        fontWeight: FontWeight.w700,
        fontSize: 17,
      ),
      bodyLarge: GoogleFonts.manrope(
        color: AppTokens.text,
        fontSize: 15,
        height: 1.45,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: GoogleFonts.manrope(
        color: AppTokens.textLight,
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w500,
      ),
      bodySmall: GoogleFonts.manrope(
        color: AppTokens.textLight,
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w600,
      ),
      labelLarge: GoogleFonts.manrope(
        color: AppTokens.text,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    );

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
      textTheme: textTheme,
      dividerColor: AppTokens.border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.r16),
          borderSide: const BorderSide(color: AppTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.r16),
          borderSide: const BorderSide(color: AppTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.r16),
          borderSide: const BorderSide(color: AppTokens.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.r16),
          borderSide: const BorderSide(color: AppTokens.warn),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.r16),
          borderSide: const BorderSide(color: AppTokens.warn, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.p20,
          vertical: 15,
        ),
        hintStyle: GoogleFonts.manrope(
          color: AppTokens.textMuted,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: GoogleFonts.manrope(
          color: AppTokens.textLight,
          fontWeight: FontWeight.w600,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppTokens.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.r20),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTokens.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.r20),
          ),
          elevation: 0,
          textStyle: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTokens.text,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppTokens.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.r20),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppTokens.primary,
          textStyle: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppTokens.surface,
        selectedColor: AppTokens.primarySoft,
        disabledColor: AppTokens.surfaceVariant,
        secondarySelectedColor: AppTokens.primarySoft,
        labelStyle: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTokens.text,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.pill),
        ),
        side: const BorderSide(color: AppTokens.border),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.p12, vertical: 4),
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
        backgroundColor: AppTokens.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.manrope(
          color: AppTokens.text,
          fontWeight: FontWeight.w700,
          fontSize: 24,
        ),
        iconTheme: const IconThemeData(color: AppTokens.text),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppTokens.text,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppTokens.primary
              : AppTokens.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppTokens.primarySoft
              : AppTokens.surfaceVariant,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      dividerTheme: const DividerThemeData(
        color: AppTokens.border,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTokens.text,
        contentTextStyle: GoogleFonts.manrope(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r16),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppTokens.surface,
        textStyle: GoogleFonts.manrope(
          color: AppTokens.text,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r16),
        ),
      ),
    );
  }
}
