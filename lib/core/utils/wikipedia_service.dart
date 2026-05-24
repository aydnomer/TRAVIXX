import 'dart:convert';
import 'package:http/http.dart' as http;

/// Wikipedia'dan mekan fotoğrafı çekme servisi.
///
/// Strateji:
/// 1. name_en ile İngilizce Wikipedia'da ara (en kapsamlı)
/// 2. Bulunamazsa name (Türkçe) ile TR Wikipedia
/// 3. Hâlâ bulunamazsa name + ' Türkiye' ile ara
///
/// Sonuçlar memory'de cache'lenir.
/// Ücretsiz, API key gerektirmiyor.
class WikipediaService {
  /// Bellek cache: pageTitle → URL (veya null = bulunamadı)
  static final Map<String, String?> _cache = {};

  /// Bir mekan ismi için Wikipedia thumbnail URL'i.
  /// Bulunamazsa null döner.
  static Future<String?> fetchThumbnail({
    required String name,
    String? nameEn,
  }) async {
    // Önce İngilizce dene (daha kapsamlı sonuçlar)
    if (nameEn != null && nameEn.isNotEmpty) {
      final url = await _trySearch(nameEn, lang: 'en');
      if (url != null) return url;
    }
    // Sonra Türkçe
    final url = await _trySearch(name, lang: 'tr');
    if (url != null) return url;

    // Son şans: 'Türkiye' eklemiş Türkçe arama
    if (!name.toLowerCase().contains('türkiye')) {
      return await _trySearch('$name Türkiye', lang: 'tr');
    }
    return null;
  }

  /// Verilen başlığı belirtilen dil Wikipedia'sında arar,
  /// sayfa varsa thumbnail URL'ini döner.
  static Future<String?> _trySearch(String title, {required String lang}) async {
    final cacheKey = '$lang:$title';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey];

    try {
      // Wikipedia REST API — page summary
      // https://en.wikipedia.org/api/rest_v1/page/summary/{title}
      final encoded = Uri.encodeComponent(title.replaceAll(' ', '_'));
      final url = Uri.parse(
        'https://$lang.wikipedia.org/api/rest_v1/page/summary/$encoded',
      );
      final response =
          await http.get(url).timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) {
        _cache[cacheKey] = null;
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Disambiguation veya redirect sayfalarını atla
      if (data['type'] == 'disambiguation') {
        _cache[cacheKey] = null;
        return null;
      }

      // Önce 'originalimage' (yüksek çözünürlük), yoksa 'thumbnail'
      String? imageUrl;
      final original = data['originalimage'];
      if (original is Map && original['source'] is String) {
        imageUrl = original['source'] as String;
      } else {
        final thumb = data['thumbnail'];
        if (thumb is Map && thumb['source'] is String) {
          imageUrl = thumb['source'] as String;
        }
      }

      _cache[cacheKey] = imageUrl;
      return imageUrl;
    } catch (_) {
      _cache[cacheKey] = null;
      return null;
    }
  }
}
