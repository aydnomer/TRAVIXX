import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  // ═══════════════════════════════════════════════════════════════
  // MARKA RENKLERİ (light/dark her ikisinde de aynı)
  // ═══════════════════════════════════════════════════════════════
  static const Color primary = Color(0xFF1A2744);
  static const Color primaryLight = Color(0xFF2D3E5E);
  static const Color primaryDark = Color(0xFF0F1828);

  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentOrangeLight = Color(0xFFFB923C);
  static const Color accentOrangeBg = Color(0xFFFFF7ED);

  static const Color gold = Color(0xFFEAB308);
  static const Color goldBg = Color(0xFFFEF9C3);

  // ═══════════════════════════════════════════════════════════════
  // LIGHT TEMASI (default)
  // ═══════════════════════════════════════════════════════════════
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF1A2744);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color accent = Color(0xFFCBD5E9);

  // ═══════════════════════════════════════════════════════════════
  // DARK TEMASI
  // ═══════════════════════════════════════════════════════════════
  static const Color darkBackground = Color(0xFF0A1020);
  static const Color darkSurface = Color(0xFF151D33);
  static const Color darkCardBorder = Color(0xFF2A3550);
  static const Color darkTextPrimary = Color(0xFFE5E7EB);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // ═══════════════════════════════════════════════════════════════
  // REAKTİF TEMA STATE
  // ═══════════════════════════════════════════════════════════════
  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.light);
  static const _prefsKey = 'theme_mode';

  static bool get isDark => mode.value == ThemeMode.dark;

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved == 'dark') {
        mode.value = ThemeMode.dark;
      } else if (saved == 'light') {
        mode.value = ThemeMode.light;
      }
    } catch (_) {}
  }

  static Future<void> toggleDark() async {
    mode.value = isDark ? ThemeMode.light : ThemeMode.dark;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, isDark ? 'dark' : 'light');
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════════════════════
  // LIGHT THEME
  // ═══════════════════════════════════════════════════════════════
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: primary,
          secondary: accentOrange,
          surface: surface,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: textPrimary,
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            side: BorderSide(color: cardBorder, width: 0.5),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: surface,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: surface,
        ),
      );

  // ═══════════════════════════════════════════════════════════════
  // DARK THEME
  // ═══════════════════════════════════════════════════════════════
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: accentOrange,
          secondary: accentOrange,
          surface: darkSurface,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: darkTextPrimary,
        ),
        scaffoldBackgroundColor: darkBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            side: BorderSide(color: darkCardBorder, width: 0.5),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: darkSurface,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: darkSurface,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: darkTextPrimary),
          bodyMedium: TextStyle(color: darkTextPrimary),
          bodySmall: TextStyle(color: darkTextSecondary),
        ),
      );
}
