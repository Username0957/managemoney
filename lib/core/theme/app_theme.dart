import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF22C55E); // Hijau utama
  static const Color accentColor = Color(0xFF16A34A);
  static const Color backgroundColor = Color(0xFFF3F4F6);
  static const Color errorColor = Color(0xFFEF4444);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        error: errorColor,
      ),
      // PERBAIKAN 1: Menggunakan CardThemeData
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18), // Card radius 18
        ),
        elevation: 2, // Soft shadow
        // PERBAIKAN 2: Menggunakan withValues(alpha: ...)
        shadowColor: Colors.black.withValues(alpha: 0.1),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),
    );
  }
}