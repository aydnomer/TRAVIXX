import 'package:flutter/material.dart';

/// Travixx giriş-sonrası tasarım sistemi (yeşil marka).
///
/// Landing ekranı eski [AppTheme] (lacivert) ile kalır; bu token'lar yalnızca
/// kullanıcı giriş yaptıktan sonra gördüğü ekranlarda kullanılır.
///
/// Kurallar: flat tasarım (gölge YOK), 1px border, font-weight max 500,
/// 6 font boyutu, 4px spacing grid, 150ms transition.
class DT {
  DT._();

  // ── Renkler ──────────────────────────────────────────────────
  static const Color primary = Color(0xFF3B6D11);
  static const Color primaryLight = Color(0xFFEAF3DE);
  static const Color primaryDark = Color(0xFF27500A);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color bg = Color(0xFFF8F7F4);
  static const Color border = Color(0xFFE8E5DE);

  static const Color textMain = Color(0xFF1A1A18);
  static const Color textSecondary = Color(0xFF6B6A65);
  static const Color textMuted = Color(0xFFA8A7A2);

  static const Color danger = Color(0xFFDC2626);

  // Kategori renkleri (kart ikon kutuları için)
  static const Color catMuseum = Color(0xFF3B6D11); // müze → yeşil
  static const Color catCastle = Color(0xFFCA8A04); // kale → sarı
  static const Color catNature = Color(0xFF0284C7); // doğa → mavi
  static const Color catMosque = Color(0xFF7C3AED); // cami → mor
  static const Color catFood = Color(0xFFDB2777); // yeme-içme → pembe
  static const Color catDefault = Color(0xFF6B6A65);

  // ── Spacing (4px grid) ───────────────────────────────────────
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;

  // ── Border radius ────────────────────────────────────────────
  static const double rSmall = 8;
  static const double rCard = 12;
  static const double rPill = 20;

  static const BorderRadius brSmall = BorderRadius.all(Radius.circular(rSmall));
  static const BorderRadius brCard = BorderRadius.all(Radius.circular(rCard));
  static const BorderRadius brPill = BorderRadius.all(Radius.circular(rPill));

  // ── Border ───────────────────────────────────────────────────
  static const BorderSide side = BorderSide(color: border, width: 1);
  static Border get boxBorder => Border.all(color: border, width: 1);

  // ── Animasyon ────────────────────────────────────────────────
  static const Duration anim = Duration(milliseconds: 150);

  // ── Tipografi (font-weight max 500, 6 boyut) ─────────────────
  static const FontWeight wRegular = FontWeight.w400;
  static const FontWeight wMedium = FontWeight.w500;

  static const TextStyle t12 =
      TextStyle(fontSize: 12, height: 1.6, color: textSecondary, fontWeight: wRegular);
  static const TextStyle t13 =
      TextStyle(fontSize: 13, height: 1.5, color: textMain, fontWeight: wRegular);
  static const TextStyle t14 =
      TextStyle(fontSize: 14, height: 1.5, color: textMain, fontWeight: wRegular);
  static const TextStyle t16 =
      TextStyle(fontSize: 16, height: 1.4, color: textMain, fontWeight: wMedium);
  static const TextStyle t20 =
      TextStyle(fontSize: 20, height: 1.3, color: textMain, fontWeight: wMedium);
  static const TextStyle t24 =
      TextStyle(fontSize: 24, height: 1.25, color: textMain, fontWeight: wMedium);

  // Sık kullanılan varyantlar
  static const TextStyle muted12 = TextStyle(
      fontSize: 12, height: 1.6, color: textMuted, fontWeight: wRegular);
  static const TextStyle label13Medium = TextStyle(
      fontSize: 13, height: 1.4, color: textMain, fontWeight: wMedium);
  static const TextStyle label14Medium = TextStyle(
      fontSize: 14, height: 1.4, color: textMain, fontWeight: wMedium);
  static const TextStyle sectionMuted = TextStyle(
      fontSize: 14, height: 1.4, color: textSecondary, fontWeight: wRegular);
  static const TextStyle primaryLink = TextStyle(
      fontSize: 14, height: 1.4, color: primary, fontWeight: wMedium);

  // ── Kategori → renk + ikon eşlemesi ──────────────────────────
  static Color categoryColor(String? category) {
    final c = (category ?? '').toLowerCase();
    if (c.contains('müze') || c.contains('muze') || c.contains('museum')) {
      return catMuseum;
    }
    if (c.contains('kale') || c.contains('castle')) return catCastle;
    if (c.contains('cami') || c.contains('mosque')) return catMosque;
    if (c.contains('restoran') ||
        c.contains('yeme') ||
        c.contains('food') ||
        c.contains('restaurant')) {
      return catFood;
    }
    if (c.contains('doğa') ||
        c.contains('doga') ||
        c.contains('park') ||
        c.contains('şelale') ||
        c.contains('selale') ||
        c.contains('mağara') ||
        c.contains('magara') ||
        c.contains('nature')) {
      return catNature;
    }
    return catDefault;
  }

  static IconData categoryIcon(String? category) {
    final c = (category ?? '').toLowerCase();
    if (c.contains('müze') || c.contains('muze') || c.contains('museum')) {
      return Icons.museum_outlined;
    }
    if (c.contains('kale') || c.contains('castle')) return Icons.castle_outlined;
    if (c.contains('cami') || c.contains('mosque')) return Icons.mosque_outlined;
    if (c.contains('restoran') ||
        c.contains('yeme') ||
        c.contains('food') ||
        c.contains('restaurant')) {
      return Icons.restaurant_outlined;
    }
    if (c.contains('şelale') ||
        c.contains('selale') ||
        c.contains('mağara') ||
        c.contains('magara') ||
        c.contains('doğa') ||
        c.contains('doga') ||
        c.contains('park') ||
        c.contains('nature')) {
      return Icons.park_outlined;
    }
    return Icons.place_outlined;
  }
}
