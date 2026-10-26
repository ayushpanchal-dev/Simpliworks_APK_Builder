import 'package:flutter/material.dart';

/// Clean, professional, modern Light Theme for Simpliworks APK Builder.
class AppTheme {
  // Brand & Surface Palette
  static const Color scaffoldBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceWhite = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5F9); // Slate 100
  static const Color borderSubtle = Color(0xFFE2E8F0); // Slate 200
  static const Color borderMedium = Color(0xFFCBD5E1); // Slate 300

  // Brand Accents
  static const Color primarySky = Color(0xFF0284C7); // Sky 600
  static const Color primarySkyHover = Color(0xFF0369A1); // Sky 700
  static const Color primaryIndigo = Color(0xFF4F46E5); // Indigo 600

  // Semantic Status Colors
  static const Color successGreen = Color(0xFF16A34A); // Emerald 600
  static const Color successBg = Color(0xFFF0FDF4); // Emerald 50
  static const Color warningAmber = Color(0xFFD97706); // Amber 600
  static const Color warningBg = Color(0xFFFFFBEB); // Amber 50
  static const Color errorRed = Color(0xFFDC2626); // Red 600
  static const Color errorBg = Color(0xFFFEF2F2); // Red 50

  // Typography Colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  // Terminal Console Colors
  static const Color consoleBackground = Color(0xFF0F172A); // Dark Slate 900
  static const Color consoleText = Color(0xFFF8FAFC);
  static const Color consoleSky = Color(0xFF38BDF8);
  static const Color consoleGreen = Color(0xFF4ADE80);
  static const Color consoleAmber = Color(0xFFFBBF24);
  static const Color consoleRed = Color(0xFFF87171);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: scaffoldBackground,
      colorScheme: const ColorScheme.light(
        primary: primarySky,
        onPrimary: surfaceWhite,
        secondary: primaryIndigo,
        surface: surfaceWhite,
        onSurface: textPrimary,
        error: errorRed,
        onError: surfaceWhite,
      ),
      fontFamily: 'Segoe UI',
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primarySky, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorRed),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
        hintStyle: const TextStyle(color: textMuted, fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primarySky,
          foregroundColor: surfaceWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderMedium),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderSubtle,
        thickness: 1,
        space: 24,
      ),
    );
  }
}
