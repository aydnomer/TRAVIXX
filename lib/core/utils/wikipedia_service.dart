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
/// Bir mekan için Wikipedia'dan toplanan veri: tarihçe + birden çok foto.
class WikiPlaceMedia {
  final String? extract; // tarihçe / açıklama metni
  final List<String> images; // birden fazla foto URL'i
  const WikiPlaceMedia({this.extract, this.images = const []});
}

class WikipediaService {
  /// Bellek cache: pageTitle → URL (veya null = bulunamadı)
  static final Map<String, String?> _cache = {};

  /// Mekan medyası cache: 'lang:title' → WikiPlaceMedia
  static final Map<String, WikiPlaceMedia> _mediaCache = {};

  /// Bir mekan için tarihçe metni + birden fazla fotoğraf çeker.
  /// Önce İngilizce, sonra Türkçe Wikipedia denenir.
  static Future<WikiPlaceMedia> fetchPlaceMedia({
    required String name,
    String? nameEn,
    int maxImages = 6,
  }) async {
    if (nameEn != null && nameEn.isNotEmpty) {
      final m = await _tryMedia(nameEn, lang: 'en', maxImages: maxImages);
      if (m.images.isNotEmpty || (m.extract?.isNotEmpty ?? false)) return m;
    }
    final tr = await _tryMedia(name, lang: 'tr', maxImages: maxImages);
    if (tr.images.isNotEmpty || (tr.extract?.isNotEmpty ?? false)) return tr;
    if (!name.toLowerCase().contains('türkiye')) {
      return _tryMedia('$name Türkiye', lang: 'tr', maxImages: maxImages);
    }
    return const WikiPlaceMedia();
  }

  static Future<WikiPlaceMedia> _tryMedia(String title,
      {required String lang, required int maxImages}) async {
    final key = '$lang:$title';
    if (_mediaCache.containsKey(key)) return _mediaCache[key]!;
    final encoded = Uri.encodeComponent(title.replaceAll(' ', '_'));

    String? extract;
    final images = <String>[];

    // 1) Summary → extract + ana görsel
    try {
      final res = await http
          .get(Uri.parse(
              'https://$lang.wikipedia.org/api/rest_v1/page/summary/$encoded'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['type'] != 'disambiguation') {
          extract = data['extract'] as String?;
          final orig = data['originalimage'];
          if (orig is Map && orig['source'] is String) {
            images.add(orig['source'] as String);
          }
        }
      }
    } catch (_) {}

    // 2) Media-list → ek görseller
    try {
      final res = await http
          .get(Uri.parse(
              'https://$lang.wikipedia.org/api/rest_v1/page/media-list/$encoded'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final items = (data['items'] as List?) ?? const [];
        for (final it in items) {
          if (images.length >= maxImages) break;
          if (it is! Map) continue;
          if (it['type'] != 'image') continue;
          final srcset = it['srcset'];
          if (srcset is List && srcset.isNotEmpty) {
            final first = srcset.first;
            if (first is Map && first['src'] is String) {
              var src = first['src'] as String;
              if (src.startsWith('//')) src = 'https:$src';
              if (!images.contains(src)) images.add(src);
            }
          }
        }
      }
    } catch (_) {}

    final result = WikiPlaceMedia(extract: extract, images: images);
    _mediaCache[key] = result;
    return result;
  }

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
