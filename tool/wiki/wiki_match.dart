// Wikipedia eşleştirme yardımcıları (saf fonksiyonlar, test edilebilir).
// tool/translate_places.dart kullanır.

import '../osm/osm_mapper.dart' show distanceKm, fold, nameTokens;

/// Uygulamanın desteklediği diller.
const List<String> appLanguages = ['tr', 'en', 'de', 'ar', 'fr', 'ru'];

/// "Atatürk Köşkü (Trabzon)" → "Atatürk Köşkü"
String stripParens(String title) =>
    title.replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '').trim();

/// Veritabanındaki ad Türkçe karaktersiz yazılmışsa ("Ataturk Kosku")
/// ve Wikipedia başlığı harf harf aynı kelimelerse ("Atatürk Köşkü"),
/// doğru yazımı döner. Kelimeler farklıysa ya da zaten doğruysa null.
String? fixedName(String dbName, String wikiTitle) {
  final wiki = stripParens(wikiTitle);
  if (wiki.isEmpty || wiki == dbName.trim()) return null;
  if (fold(wiki) != fold(dbName.trim())) return null;
  return wiki;
}

/// Arama sonucundaki makale bu mekan mı?
/// Koordinat varsa [maxKm] içinde olmalı ve adlarında ortak anlamlı kelime
/// bulunmalı; koordinat yoksa adlar (parantez hariç) birebir aynı olmalı.
bool isSamePlace({
  required String name,
  double? lat,
  double? lng,
  required String title,
  double? wikiLat,
  double? wikiLng,
  double maxKm = 3,
}) {
  final bare = stripParens(title);
  if (lat == null || lng == null || wikiLat == null || wikiLng == null) {
    return fold(bare) == fold(name.trim());
  }
  if (distanceKm(lat, lng, wikiLat, wikiLng) > maxKm) return false;
  final a = nameTokens(name), b = nameTokens(bare);
  if (a.isEmpty || b.isEmpty) return fold(bare) == fold(name.trim());
  return a.intersection(b).isNotEmpty;
}

/// Wikipedia giriş metnini kısaltır: en çok [maxChars] karakter, cümle
/// sonunda keser. Boşsa null.
String? clip(String? text, int maxChars) {
  if (text == null) return null;
  final t = text
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .trim();
  if (t.isEmpty) return null;
  if (t.length <= maxChars) return t;
  final cut = t.substring(0, maxChars);
  final end = cut.lastIndexOf(RegExp(r'[.!?。؟]\s'));
  return end > maxChars ~/ 3 ? cut.substring(0, end + 1).trim() : '${cut.trim()}…';
}

/// Kısa açıklama: giriş metninin ilk 1-2 cümlesi.
String? shortDescription(String? intro) => clip(intro?.split('\n').first, 400);

/// "tr:Efes" → (lang: tr, title: Efes). Biçim uymazsa null.
({String lang, String title})? parseWikiTag(String? tag) {
  if (tag == null) return null;
  final i = tag.indexOf(':');
  if (i < 2 || i > 3 || i == tag.length - 1) return null;
  return (lang: tag.substring(0, i), title: tag.substring(i + 1).trim());
}
