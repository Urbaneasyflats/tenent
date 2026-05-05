import 'package:flutter/material.dart';

import '../models/app_models.dart';

class AppTheme {
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryHover = Color(0xFF1D4ED8);
  static const Color primarySoft = Color(0xFFEFF6FF);
  static const Color primaryTone = Color(0xFFDBEAFE);

  static const Color secondary = Color(0xFFF97316);
  static const Color secondaryHover = Color(0xFFEA580C);

  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF3F4F6);

  static const Color border = Color(0xFFE5E7EB);
  static const Color borderStrong = Color(0xFFD1D5DB);
  static const Color borderSoft = Color(0xFFF3F4F6);

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF6B7280);

  static const double radiusSmall = 8;
  static const double radiusMedium = 16;
  static const double radiusLarge = 24;

  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(16, 24, 16, 24);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: Colors.white,
      error: Color(0xFFDC2626),
      onError: Colors.white,
      surface: surface,
      onSurface: textPrimary,
    ),
    scaffoldBackgroundColor: background,
    canvasColor: background,
    dividerColor: border,
    shadowColor: const Color(0x14111827),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 30,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        height: 1.333,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        height: 1.333,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        height: 1.556,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        height: 1.429,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.429,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.333,
        fontWeight: FontWeight.w400,
        color: textMuted,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        height: 1.429,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        height: 1.333,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        height: 1.273,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 18,
        height: 1.556,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        side: const BorderSide(color: borderSoft),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: surface,
      hintStyle: const TextStyle(
        color: textMuted,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: const TextStyle(
        color: textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: borderStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: borderStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: Color(0xFFFCA5A5)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: textPrimary,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF93C5FD),
        disabledForegroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.429,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textSecondary,
        disabledForegroundColor: textMuted,
        side: const BorderSide(color: borderStrong, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.429,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: textSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.429,
        ),
      ),
    ),
  );

  static Color toneColor(UiTone tone) {
    return switch (tone) {
      UiTone.brand => const Color(0xFF1E40AF),
      UiTone.success => const Color(0xFF166534),
      UiTone.warning => const Color(0xFF854D0E),
      UiTone.danger => const Color(0xFF991B1B),
      UiTone.neutral => const Color(0xFF1F2937),
    };
  }

  static Color toneContainer(UiTone tone) {
    return switch (tone) {
      UiTone.brand => const Color(0xFFDBEAFE),
      UiTone.success => const Color(0xFFDCFCE7),
      UiTone.warning => const Color(0xFFFEF9C3),
      UiTone.danger => const Color(0xFFFEE2E2),
      UiTone.neutral => const Color(0xFFF3F4F6),
    };
  }

  static Color toneSoft(UiTone tone) {
    return switch (tone) {
      UiTone.brand => primarySoft,
      UiTone.success => const Color(0xFFF0FDF4),
      UiTone.warning => const Color(0xFFFEFCE8),
      UiTone.danger => const Color(0xFFFEF2F2),
      UiTone.neutral => surfaceMuted,
    };
  }
}
