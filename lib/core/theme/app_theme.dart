import 'package:flutter/material.dart';

class AppTheme {
  // Primary Seed Color: Teal / Electric Blue vibe
  static const Color _seedColor = Color(0xFF009688);

  // LIGHT THEME
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
      primary: const Color(0xFF00695C), // Deep Teal
      secondary: const Color(0xFF004D40), // Darker Teal for accents
    ),
    scaffoldBackgroundColor: const Color(
      0xFFF5F5F5,
    ), // Light Grey, not pure white
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.black87,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
    ),
  );

  // DARK THEME
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
      primary: const Color(0xFF80CBC4), // Lighter Teal for dark mode contrast
      surface: const Color(0xFF1E1E1E), // Dark Grey surface
    ),
    scaffoldBackgroundColor: const Color(0xFF121212), // True Dark
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: Colors.white10,
        ), // Subtle border in dark mode
      ),
    ),
  );
}
