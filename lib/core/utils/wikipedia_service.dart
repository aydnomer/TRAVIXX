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
    bool ok(WikiPlaceMedia m) =>
        m.images.isNotEmpty || ((m.extract?.trim().length ?? 0) > 60);

    // 1) Türkçe Wikipedia'da ARAMA ile gerçek başlığı bul (en güvenilir).
    //    Mekan adları Türkçe karaktersiz olabilir ("Elazig Muzesi").
    //    Önce deasciify ile "Elazığ Müzesi"ne çevirip aramak isabeti artırır.
    final deascii = _deAsciify(name);
    for (final q in {deascii, name}) {
      final trTitle = await _searchTitle(q, lang: 'tr');
      if (trTitle != null) {
        final m = await _tryMedia(trTitle, lang: 'tr', maxImages: maxImages);
        if (ok(m)) return m;
      }
    }

    // 2) İngilizce Wikipedia'da arama (nameEn ile)
    if (nameEn != null && nameEn.isNotEmpty) {
      final enTitle = await _searchTitle(nameEn, lang: 'en');
      if (enTitle != null) {
        final m = await _tryMedia(enTitle, lang: 'en', maxImages: maxImages);
        if (ok(m)) return m;
      }
    }

    // 3) Doğrudan başlık denemeleri (arama başarısızsa)
    final direct = await _tryMedia(name, lang: 'tr', maxImages: maxImages);
    if (ok(direct)) return direct;
    return const WikiPlaceMedia();
  }

  /// Yaygın Türkçe yer-kelimeleri ve il adlarını doğru yazıma çevirir.
  /// (DB'de Türkçe karaktersiz yazılmış adlar için: "Elazig Muzesi" →
  /// "Elazığ Müzesi"). Kelime bazlı, büyük/küçük harf korunur.
  static const Map<String, String> _deAsciiMap = {
    // Yer türleri
    'muze': 'müze', 'muzesi': 'müzesi',
    'sarayi': 'sarayı', 'kopru': 'köprü', 'koprusu': 'köprüsü',
    'selale': 'şelale', 'selalesi': 'şelalesi',
    'magara': 'mağara', 'magarasi': 'mağarası',
    'golu': 'gölü', 'gol': 'göl',
    'dagi': 'dağı', 'dag': 'dağ',
    'oren': 'ören', 'oreni': 'öreni', 'orenyeri': 'örenyeri',
    'cesme': 'çeşme', 'carsi': 'çarşı', 'carsisi': 'çarşısı',
    'koy': 'köy', 'koyu': 'köyü', 'kosk': 'köşk', 'kosku': 'köşkü',
    'turbe': 'türbe', 'turbesi': 'türbesi',
    'hani': 'hanı', 'hamami': 'hamamı', 'bahcesi': 'bahçesi',
    // İl adları (Türkçe karakterli olanlar)
    'elazig': 'Elazığ', 'istanbul': 'İstanbul', 'mugla': 'Muğla',
    'mus': 'Muş', 'usak': 'Uşak', 'sirnak': 'Şırnak', 'igdir': 'Iğdır',
    'aydin': 'Aydın', 'balikesir': 'Balıkesir', 'diyarbakir': 'Diyarbakır',
    'kirklareli': 'Kırklareli', 'kirsehir': 'Kırşehir',
    'kirikkale': 'Kırıkkale', 'tekirdag': 'Tekirdağ',
    'canakkale': 'Çanakkale', 'cankiri': 'Çankırı', 'corum': 'Çorum',
    'nigde': 'Niğde', 'agri': 'Ağrı', 'gumushane': 'Gümüşhane',
    'sanliurfa': 'Şanlıurfa', 'kahramanmaras': 'Kahramanmaraş',
    'bingol': 'Bingöl', 'bartin': 'Bartın',
  };

  static String _deAsciify(String input) {
    final words = input.split(RegExp(r'\s+'));
    return words.map((w) {
      final lower = w.toLowerCase();
      final fixed = _deAsciiMap[lower];
      if (fixed == null) return w;
      // Sözlük değeri zaten büyük harfle başlıyorsa onu kullan,
      // değilse orijinalin baş harfini koru.
      if (fixed[0] == fixed[0].toUpperCase()) return fixed;
      final capped = w.isNotEmpty && w[0] == w[0].toUpperCase();
      return capped ? '${fixed[0].toUpperCase()}${fixed.substring(1)}' : fixed;
    }).join(' ');
  }

  /// Wikipedia arama API'si ile sorguya en uygun sayfa başlığını bulur.
  /// Birden çok sonuç çekip kelime örtüşmesine göre en iyisini seçer
  /// (şehir maddesi "X (il)" gibi alakasız sonuçları eler).
  static final Map<String, String?> _titleCache = {};
  static Future<String?> _searchTitle(String query,
      {required String lang}) async {
    final key = '$lang|$query';
    if (_titleCache.containsKey(key)) return _titleCache[key];
    try {
      final q = Uri.encodeQueryComponent(query);
      final res = await http
          .get(Uri.parse(
              'https://$lang.wikipedia.org/w/api.php?format=json&action=query'
              '&list=search&srlimit=6&srsearch=$q'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final hits = (data['query']?['search']) as List?;
        if (hits != null && hits.isNotEmpty) {
          final best = _bestMatch(query, hits);
          _titleCache[key] = best;
          return best;
        }
      }
    } catch (_) {}
    _titleCache[key] = null;
    return null;
  }

  /// Sorgu kelimeleriyle en çok örtüşen başlığı seçer.
  static String? _bestMatch(String query, List hits) {
    final qWords = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .toSet();
    String? best;
    double bestScore = -1;
    for (final h in hits) {
      if (h is! Map) continue;
      final title = h['title'] as String?;
      if (title == null) continue;
      final tLower = title.toLowerCase();
      final tWords = tLower.split(RegExp(r'\s+')).toSet();
      var score = qWords.where((w) => tWords.contains(w)).length.toDouble();
      // Şehir/il maddesi gibi tek-kavram sonuçları cezalandır
      if (tLower.contains('(il)') ||
          tLower.contains('(şehir)') ||
          tLower.contains('(ilçe)')) {
        score -= 2;
      }
      if (score > bestScore) {
        bestScore = score;
        best = title;
      }
    }
    // Hiç örtüşme yoksa ilk sonucu döndürme (alakasız olabilir)
    return bestScore > 0 ? best : (hits.first as Map)['title'] as String?;
  }

  static Future<WikiPlaceMedia> _tryMedia(String title,
      {required String lang, required int maxImages}) async {
    final key = '$lang:$title';
    if (_mediaCache.containsKey(key)) return _mediaCache[key]!;
    final encoded = Uri.encodeComponent(title.replaceAll(' ', '_'));

    String? extract;
    final images = <String>[];

    // 1) Summary → kısa özet + ana görsel (disambiguation kontrolü)
    try {
      final res = await http
          .get(Uri.parse(
              'https://$lang.wikipedia.org/api/rest_v1/page/summary/$encoded'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['type'] == 'disambiguation') {
          _mediaCache[key] = const WikiPlaceMedia();
          return const WikiPlaceMedia();
        }
        extract = data['extract'] as String?;
        final orig = data['originalimage'];
        if (orig is Map && orig['source'] is String) {
          images.add(orig['source'] as String);
        }
      }
    } catch (_) {}

    // 2) Tam makale metni → detaylı tarihçe (çok paragraflı)
    try {
      final res = await http
          .get(Uri.parse(
              'https://$lang.wikipedia.org/w/api.php?format=json&action=query'
              '&prop=extracts&explaintext=1&redirects=1&exsectionformat=plain'
              '&titles=$encoded'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final pages = (data['query']?['pages']) as Map<String, dynamic>?;
        if (pages != null && pages.isNotEmpty) {
          final page = pages.values.first as Map<String, dynamic>;
          final full = page['extract'] as String?;
          if (full != null && full.trim().length > (extract?.length ?? 0)) {
            extract = _truncate(full.trim(), 2400);
          }
        }
      }
    } catch (_) {}

    // 3) Media-list → ek görseller
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
              if (!_isRealPhoto(src)) continue; // ikon/harita/bayrak ele
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

  /// Fotoğraf olmayan görselleri (ikon, harita, bayrak, logo, ses) eler.
  static bool _isRealPhoto(String url) {
    final u = url.toLowerCase();
    // Vektör/ses/sembol uzantıları fotoğraf değil
    if (u.endsWith('.svg') ||
        u.contains('.svg/') ||
        u.endsWith('.ogg') ||
        u.endsWith('.oga') ||
        u.endsWith('.wav')) {
      return false;
    }
    // İsim kalıplarına göre alakasız görselleri ele
    const bad = [
      'icon', 'logo', 'map', 'harita', 'flag', 'bayrak', 'locator',
      'coat_of_arms', 'arms', 'symbol', 'wiki', 'commons-logo',
      'edit-', 'ambox', 'question', 'disambig',
    ];
    return !bad.any((b) => u.contains(b));
  }

  /// Metni en yakın paragraf/cümle sınırında kısaltır, sonuna "…" ekler.
  static String _truncate(String text, int maxLen) {
    if (text.length <= maxLen) return text;
    var cut = text.substring(0, maxLen);
    // Önce paragraf sonu, yoksa cümle sonu ara
    final nl = cut.lastIndexOf('\n');
    final dot = cut.lastIndexOf('. ');
    final boundary = nl > maxLen * 0.6 ? nl : (dot > maxLen * 0.5 ? dot + 1 : -1);
    if (boundary > 0) cut = cut.substring(0, boundary);
    return '${cut.trim()}…';
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
