import 'package:flutter/material.dart';

/// Design tokens for Khalashi Phase 0 shell.
/// Warm road-travel palette — not purple/indigo defaults.
class KhalashiColors {
  static const Color saffron = Color(0xFFC45C26);
  static const Color deepTeal = Color(0xFF0F3D3E);
  static const Color sand = Color(0xFFF3E8D8);
  static const Color dusk = Color(0xFF1A2B2B);
  static const Color mist = Color(0xFFE8F0EF);
}

ThemeData buildKhalashiTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: KhalashiColors.deepTeal,
      primary: KhalashiColors.deepTeal,
      secondary: KhalashiColors.saffron,
      surface: KhalashiColors.sand,
      brightness: Brightness.light,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: KhalashiColors.sand,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: KhalashiColors.dusk,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: KhalashiColors.deepTeal,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: KhalashiColors.deepTeal,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: KhalashiColors.deepTeal),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withOpacity(0.85),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
