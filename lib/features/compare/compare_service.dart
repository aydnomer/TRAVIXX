import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Karşılaştırma sepeti. Kullanıcı en fazla 4 mekan ekleyebilir.
/// ValueNotifier ile tüm UI reaktif olarak güncellenir.
/// SharedPreferences ile persist edilir (sayfa yenilense de kalır).
class CompareService {
  static const _prefsKey = 'compare_basket';
  static const maxItems = 4;

  /// Aktif sepetteki mekan ID'leri (reaktif)
  static final ValueNotifier<List<String>> basket = ValueNotifier([]);

  /// Uygulama başlangıcında çağrılır
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_prefsKey) ?? [];
      basket.value = ids;
    } catch (_) {}
  }

  /// Mekan zaten sepete eklenmiş mi?
  static bool contains(String placeId) => basket.value.contains(placeId);

  /// Toggle ekle/çıkar. Limit aşılırsa false döner.
  static Future<bool> toggle(String placeId) async {
    final current = List<String>.from(basket.value);
    if (current.contains(placeId)) {
      current.remove(placeId);
    } else {
      if (current.length >= maxItems) return false;
      current.add(placeId);
    }
    basket.value = current;
    await _persist(current);
    return true;
  }

  /// Sepeti temizle
  static Future<void> clear() async {
    basket.value = [];
    await _persist(const []);
  }

  /// Bir mekanı sepetten çıkar
  static Future<void> remove(String placeId) async {
    final current = List<String>.from(basket.value);
    current.remove(placeId);
    basket.value = current;
    await _persist(current);
  }

  static Future<void> _persist(List<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, ids);
    } catch (_) {}
  }
}
