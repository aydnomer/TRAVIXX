import 'package:flutter/material.dart';

class AppTheme {
  // Lacivert ana paleti
  static const Color primary = Color(0xFF1A2744);
  static const Color primaryLight = Color(0xFF2D3E5E);
  static const Color primaryDark = Color(0xFF0F1828);

  // Turuncu vurgu (Travixx imza rengi)
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentOrangeLight = Color(0xFFFB923C);
  static const Color accentOrangeBg = Color(0xFFFFF7ED);

  // Altın (ikincil vurgu)
  static const Color gold = Color(0xFFEAB308);
  static const Color goldBg = Color(0xFFFEF9C3);

  // Nötr arka plan/yüzey
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE2E8F0);

  // Metin
  static const Color textPrimary = Color(0xFF1A2744);
  static const Color textSecondary = Color(0xFF64748B);

  // Eski "accent" sabitleri — koyu zeminde okunabilir açık ton
  static const Color accent = Color(0xFFCBD5E9);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: accentOrange,
      surface: surface,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
  );
}
