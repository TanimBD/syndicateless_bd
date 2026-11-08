import 'package:flutter/material.dart';

/// Bangladesh flag inspired palette.
class AppColors {
  static const green = Color(0xFF006A4E);
  static const greenDark = Color(0xFF004D38);
  static const red = Color(0xFFF42A41);
  static const amber = Color(0xFFF5A623);
  static const blue = Color(0xFF1E6FD9);
  static const surface = Color(0xFFF4F7F5);
}

ThemeData buildTheme(Brightness b) {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.green,
    brightness: b,
    primary: b == Brightness.light ? AppColors.green : const Color(0xFF5FD3A8),
    secondary: AppColors.red,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor:
        b == Brightness.light ? AppColors.surface : scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: b == Brightness.light ? AppColors.green : scheme.surface,
      foregroundColor: b == Brightness.light ? Colors.white : scheme.onSurface,
      centerTitle: false,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: b == Brightness.light ? Colors.white : scheme.surfaceContainer,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
