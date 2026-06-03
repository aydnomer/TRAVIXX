import 'package:flutter/material.dart';

/// Giriş sonrası ana navigasyon hedefleri (web nav rail + mobil bottom nav ortak).
class NavDest {
  final String route;
  final IconData icon;
  final String label;
  const NavDest(this.route, this.icon, this.label);
}

class NavDestinations {
  NavDestinations._();

  /// Ana hedefler — sırayla: Ana Sayfa, Keşfet, Harita, Rotalar, Şehirler.
  static const List<NavDest> main = [
    NavDest('/home', Icons.home_outlined, 'Ana Sayfa'),
    NavDest('/search', Icons.explore_outlined, 'Keşfet'),
    NavDest('/map', Icons.map_outlined, 'Harita'),
    NavDest('/trip-wizard', Icons.route_outlined, 'Rotalar'),
    NavDest('/cities', Icons.location_city_outlined, 'Şehirler'),
  ];

  /// Mobil bottom nav: Harita ortada (büyük), Şehirler yerine Profil.
  static const List<NavDest> mobile = [
    NavDest('/home', Icons.home_outlined, 'Ana Sayfa'),
    NavDest('/search', Icons.explore_outlined, 'Keşfet'),
    NavDest('/map', Icons.map_outlined, 'Harita'),
    NavDest('/trip-wizard', Icons.route_outlined, 'Rotalar'),
    NavDest('/profile', Icons.person_outline, 'Profil'),
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
