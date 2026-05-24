import 'package:shared_preferences/shared_preferences.dart';

/// Son görüntülenen mekan id'lerini SharedPreferences'ta tutar.
/// Max 10 öğe, yeni en başa eklenir.
class RecentPlaces {
  static const _prefsKey = 'recent_place_ids';
  static const _maxItems = 10;

  /// Bir mekanı ziyaret listesine ekle (zaten varsa öne taşı)
  static Future<void> add(String placeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefsKey) ?? [];
      list.remove(placeId); // varsa kaldır
      list.insert(0, placeId); // başa ekle
      if (list.length > _maxItems) {
        list.removeRange(_maxItems, list.length);
      }
      await prefs.setStringList(_prefsKey, list);
    } catch (_) {}
  }

  /// Son görüntülenen mekan id'leri (yeni→eski)
  static Future<List<String>> getIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_prefsKey) ?? const [];
    } catch (_) {
      return const [];
    }
  }

  /// Listeyi temizle
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
  }
}
