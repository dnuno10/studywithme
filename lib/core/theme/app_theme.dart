import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const background = Color(0xFF07111F);
  static const surface = Color(0xFF0E1A2C);
  static const surfaceAlt = Color(0xFF13233B);
  static const panel = Color(0xFF0B1727);
  static const border = Color(0xFF27405E);
  static const borderStrong = Color(0xFF53E6B3);
  static const primary = Color(0xFF53E6B3);
  static const secondary = Color(0xFF7BDFF6);
  static const warning = Color(0xFFFFC857);
  static const danger = Color(0xFFFF6B6B);
  static const text = Color(0xFFEAF4FF);
  static const muted = Color(0xFF9FB3C8);
  static const success = Color(0xFF79F2A8);
}

class AppTheme {
  static ThemeData light() {
    final baseBody = GoogleFonts.arimoTextTheme();
    final mono = GoogleFonts.ibmPlexMonoTextTheme();

    final textTheme = baseBody.copyWith(
      displayLarge: mono.displayLarge?.copyWith(
        color: AppColors.text,
        fontWeight: FontWeight.w600,
      ),
      displayMedium: mono.displayMedium?.copyWith(
        color: AppColors.text,
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: mono.headlineLarge?.copyWith(
        color: AppColors.text,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: mono.headlineMedium?.copyWith(
        color: AppColors.text,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: mono.titleLarge?.copyWith(
        color: AppColors.text,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: mono.titleMedium?.copyWith(
        color: AppColors.text,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: mono.titleSmall?.copyWith(
        color: AppColors.text,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: baseBody.bodyLarge?.copyWith(
        color: AppColors.text,
        height: 1.5,
      ),
      bodyMedium: baseBody.bodyMedium?.copyWith(
        color: AppColors.text,
        height: 1.5,
      ),
      bodySmall: baseBody.bodySmall?.copyWith(
        color: AppColors.muted,
        height: 1.45,
      ),
      labelLarge: mono.labelLarge?.copyWith(
        color: AppColors.text,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
      labelMedium: mono.labelMedium?.copyWith(
        color: AppColors.text,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
      labelSmall: mono.labelSmall?.copyWith(
        color: AppColors.muted,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.6,
      ),
    );

    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: AppColors.background,
      secondary: AppColors.secondary,
      onSecondary: AppColors.background,
      error: AppColors.danger,
      onError: AppColors.text,
      surface: AppColors.surface,
      onSurface: AppColors.text,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceAlt,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.text),
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppColors.borderStrong),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.panel,
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        contentPadding: const EdgeInsets.all(18),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.borderStrong, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: textTheme.labelLarge,
          minimumSize: const Size.fromHeight(52),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.background,
      ),
    );
  }
}
