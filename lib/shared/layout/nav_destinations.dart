import 'package:flutter/material.dart';

import '../../core/i18n/i18n.dart';

/// Giriş sonrası ana navigasyon hedefleri (web nav rail + mobil bottom nav ortak).
class NavDest {
  final String route;
  final IconData icon;
  /// I18n anahtarı — görünen ad [label] ile aktif dilde döner.
  final String labelKey;
  const NavDest(this.route, this.icon, this.labelKey);

  String get label => I18n.t(labelKey);
}

class NavDestinations {
  NavDestinations._();

  /// Ana hedefler — sırayla: Ana Sayfa, Keşfet, Harita, Rotalar, Şehirler.
  static const List<NavDest> main = [
    NavDest('/home', Icons.home_outlined, 'ah.nav.home'),
    NavDest('/search', Icons.explore_outlined, 'ah.nav.explore'),
    NavDest('/map', Icons.map_outlined, 'ah.nav.map'),
    NavDest('/trip-wizard', Icons.route_outlined, 'ah.nav.routes'),
    NavDest('/cities', Icons.location_city_outlined, 'ah.nav.cities'),
  ];

  /// Mobil bottom nav: Harita ortada (büyük), Şehirler yerine Profil.
  static const List<NavDest> mobile = [
    NavDest('/home', Icons.home_outlined, 'ah.nav.home'),
    NavDest('/search', Icons.explore_outlined, 'ah.nav.explore'),
    NavDest('/map', Icons.map_outlined, 'ah.nav.map'),
    NavDest('/trip-wizard', Icons.route_outlined, 'ah.nav.routes'),
    NavDest('/profile', Icons.person_outline, 'ah.nav.profile'),
  ];

  /// Verilen yol bu hedefle eşleşiyor mu (aktif sekme tespiti).
  static bool isActive(String current, String route) {
    if (route == '/home') return current == '/' || current == '/home';
    return current == route || current.startsWith('$route/');
  }
}

/// Kullanıcı e-postasından baş harf(ler) üretir (avatar için).
String avatarInitials(String? email, {String? name}) {
  final src = (name != null && name.trim().isNotEmpty) ? name.trim() : (email ?? '');
  if (src.isEmpty) return 'G';
  final clean = src.split('@').first.trim();
  if (clean.isEmpty) return 'G';
  final parts = clean.split(RegExp(r'[\s._-]+')).where((p) => p.isNotEmpty).toList();
  if (parts.length >= 2) {
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
  return clean[0].toUpperCase();
}
