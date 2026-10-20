// Mekan içeriğini Wikipedia'nın dil sürümlerinden 6 dile taşır.
//
// Her mekan için ilgili Wikipedia makalesini bulur (OSM'den gelen wikidata/
// wikipedia etiketi, yoksa Türkçe Wikipedia'da ad + konum eşleşmesi), sonra
// Wikidata üzerinden tr/en/de/ar/fr/ru makalelerinin giriş metnini alıp
// `place_translations` tablosuna yazar:
//   name        ← o dildeki makale adı / Wikidata etiketi
//   description ← giriş metninin ilk paragrafı (kısa)
//   history     ← giriş metninin tamamı (en çok ~4000 karakter)
//
// Aynı geçişte `places` tablosundaki içerik de düzeltilir:
//   - Türkçe karaktersiz ad, Wikipedia başlığı aynı kelimelerse düzeltilir
//     ("Ataturk Kosku" → "Atatürk Köşkü"); farklı kelimelere dokunulmaz.
//   - Boş `history` Türkçe giriş metniyle, boş `wikidata` Q-kimliğiyle dolar.
//
// Wikipedia metinleri CC BY-SA; uygulama "Kaynak: Wikipedia" gösterir.
// Wikipedia'da makalesi olmayan mekanlar atlanır (uygulama TR/EN'e düşer).
//
// ── Çalıştırma ──
// GitHub Actions: "Translate places (Wikipedia)" iş akışı.
// Yerelde:
//   SUPABASE_URL=https://xxxx.supabase.co \
//   SUPABASE_SERVICE_ROLE_KEY=<service_role> \
//   dart run tool/translate_places.dart [--dry-run] [--limit=50] [--force]
//
// --force: çevirisi olan mekanları da yeniden işler.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'wiki/wiki_match.dart';

const _userAgent =
    'TravixxTranslator/1.0 (https://github.com/aydnomer/TRAVIXX)';

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final force = args.contains('--force');
  final limitArg =
      args.firstWhere((a) => a.startsWith('--limit='), orElse: () => '');
  final limit = limitArg.isEmpty ? null : int.tryParse(limitArg.substring(8));

  final url = Platform.environment['SUPABASE_URL'];
  final key = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];
  if (url == null || key == null || url.isEmpty || key.isEmpty) {
    stderr.writeln('HATA: SUPABASE_URL ve SUPABASE_SERVICE_ROLE_KEY gerekli.');
    exit(1);
  }
  final base = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  final headers = {
    'apikey': key,
    'Authorization': 'Bearer $key',
    'Content-Type': 'application/json',
  };

  // Elle girilmişlerin hepsi + OSM'den Wikipedia/Wikidata bağlantısı olanlar.
  // (Bağlantısız binlerce OSM plajı için arama yapmak boşa olur.)
  final places = await _fetchAll(
    '$base/rest/v1/places?select=id,name,latitude,longitude,history,wikidata,wikipedia,source'
    '&or=(source.eq.travixx,wikidata.not.is.null,wikipedia.not.is.null)',
    headers,
  );
  final done = force
      ? <String>{}
      : (await _fetchAll(
              '$base/rest/v1/place_translations?select=place_id', headers))
          .map((r) => r['place_id'].toString())
          .toSet();
  final todo = places.where((p) => !done.contains(p['id'].toString())).toList();
  stdout.writeln('${places.length} aday mekan, ${todo.length} işlenecek.\n');

  var matched = 0, rowsWritten = 0, namesFixed = 0, failures = 0, seen = 0;
  final perLang = {for (final l in appLanguages) l: 0};

  for (final p in todo) {
    if (limit != null && seen >= limit) break;
    seen++;
    final id = p['id'].toString();
    final name = (p['name'] ?? '').toString();
    stdout.write('${p['source'] == 'osm' ? 'osm' : '   '} $name … ');

    try {
      final qid = await _resolveQid(p);
      if (qid == null) {
        stdout.writeln('Wikipedia yok');
        continue;
      }
      final entity = await _entity(qid);
      if (entity == null) {
        stdout.writeln('Wikidata okunamadı');
        failures++;
        continue;
      }
      matched++;

      final rows = <Map<String, dynamic>>[];
      String? trTitle, trIntro;
      for (final lang in appLanguages) {
        final title = entity.sitelinks[lang];
        final intro = title == null ? null : await _intro(lang, title);
        final label = entity.labels[lang] ?? (title == null ? null : stripParens(title));
        if (lang == 'tr') {
          trTitle = title;
          trIntro = intro;
        }
        if (label == null && intro == null) continue;
        rows.add({
          'place_id': id,
          'lang': lang,
          'name': label,
          'description': shortDescription(intro),
          'history': clip(intro, 4000),
          'source': 'wikipedia',
          'source_url': title == null
              ? 'https://www.wikidata.org/wiki/$qid'
              : 'https://$lang.wikipedia.org/wiki/${Uri.encodeComponent(title.replaceAll(' ', '_'))}',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
        perLang[lang] = perLang[lang]! + 1;
      }

      final patch = <String, dynamic>{};
      if (p['wikidata'] == null) patch['wikidata'] = qid;
      final betterName = fixedName(name, trTitle ?? entity.labels['tr'] ?? '');
      if (betterName != null) patch['name'] = betterName;
      final history = (p['history'] ?? '').toString();
      if (history.trim().length < 100 && (trIntro?.length ?? 0) > 200) {
        patch['history'] = clip(trIntro, 4000);
      }

      if (!dryRun) {
        if (rows.isNotEmpty) await _upsertTranslations(base, headers, rows);
        if (patch.isNotEmpty) await _patchPlace(base, headers, id, patch);
      }
      rowsWritten += rows.length;
      if (betterName != null) namesFixed++;
      stdout.writeln('$qid · ${rows.map((r) => r['lang']).join(',')}'
          '${betterName != null ? ' · ad → $betterName' : ''}'
          '${dryRun ? ' (deneme)' : ''}');
    } catch (e) {
      failures++;
      stdout.writeln('HATA: $e');
    }

    // Wikimedia'ya nazik ol
    await Future.delayed(const Duration(milliseconds: 300));
  }

  stdout.writeln('\n── Bitti ──');
  stdout.writeln('İşlenen: $seen | Wikipedia eşleşen: $matched | '
      'çeviri satırı: $rowsWritten | düzeltilen ad: $namesFixed | hata: $failures');
  perLang.forEach((k, v) => stdout.writeln('  $k: $v'));
  if (failures > 0 && failures * 10 > seen) exitCode = 2;
}

// ── Wikipedia / Wikidata ─────────────────────────────────────────

/// Mekanın Wikidata kimliği: etiketten, ya da Türkçe Wikipedia aramasından.
Future<String?> _resolveQid(Map<String, dynamic> p) async {
  final tagged = p['wikidata']?.toString();
  if (tagged != null && RegExp(r'^Q\d+$').hasMatch(tagged)) return tagged;

  final wikiTag = parseWikiTag(p['wikipedia']?.toString());
  if (wikiTag != null) {
    final pages = await _pages(wikiTag.lang, [wikiTag.title]);
    if (pages.isNotEmpty && pages.first.qid != null) return pages.first.qid;
  }

  // Ad + konum ile Türkçe Wikipedia'da ara
  final name = (p['name'] ?? '').toString();
  if (name.trim().isEmpty) return null;
  final search = await _api('tr', {
    'action': 'query',
    'list': 'search',
    'srsearch': name,
    'srlimit': '5',
    'srnamespace': '0',
  });
  final titles = ((search?['query']?['search'] as List?) ?? const [])
      .map((s) => (s as Map)['title'].toString())
      .toList();
  if (titles.isEmpty) return null;
  final pages = await _pages('tr', titles);
  final lat = (p['latitude'] as num?)?.toDouble();
  final lng = (p['longitude'] as num?)?.toDouble();
  // Arama sırasını koru: ilk uyan makale
  for (final t in titles) {
    final page = pages.where((pg) => pg.title == t || pg.from == t).firstOrNull;
    if (page == null || page.qid == null) continue;
    if (isSamePlace(
      name: name,
      lat: lat,
      lng: lng,
      title: page.title,
      wikiLat: page.lat,
      wikiLng: page.lng,
    )) {
      return page.qid;
    }
  }
  return null;
}

class _Page {
  final String title;
  final String? from; // yönlendirme kaynağı
  final String? qid;
  final double? lat, lng;
  _Page(this.title, this.from, this.qid, this.lat, this.lng);
}

/// Başlıkların Wikidata kimliği ve koordinatı (tek istekte).
Future<List<_Page>> _pages(String lang, List<String> titles) async {
  final data = await _api(lang, {
    'action': 'query',
    'titles': titles.join('|'),
    'prop': 'coordinates|pageprops',
    'ppprop': 'wikibase_item|disambiguation',
    'redirects': '1',
  });
  final q = data?['query'] as Map?;
  if (q == null) return const [];
  final redirectFrom = <String, String>{
    for (final r in (q['redirects'] as List?) ?? const [])
      (r as Map)['to'].toString(): r['from'].toString(),
  };
  final out = <_Page>[];
  for (final pg in ((q['pages'] as Map?) ?? const {}).values) {
    final m = pg as Map;
    if (m.containsKey('missing')) continue;
    final props = (m['pageprops'] as Map?) ?? const {};
    if (props.containsKey('disambiguation')) continue;
    final coords = (m['coordinates'] as List?)?.cast<Map>();
    final title = m['title'].toString();
    out.add(_Page(
      title,
      redirectFrom[title],
      props['wikibase_item']?.toString(),
      (coords?.firstOrNull?['lat'] as num?)?.toDouble(),
      (coords?.firstOrNull?['lon'] as num?)?.toDouble(),
    ));
  }
  return out;
}

class _Entity {
  final Map<String, String> labels; // lang → etiket
  final Map<String, String> sitelinks; // lang → makale başlığı
  _Entity(this.labels, this.sitelinks);
}

Future<_Entity?> _entity(String qid) async {
  final res = await _get(Uri.https('www.wikidata.org', '/w/api.php', {
    'action': 'wbgetentities',
    'ids': qid,
    'props': 'labels|sitelinks',
    'languages': appLanguages.join('|'),
    'sitefilter': appLanguages.map((l) => '${l}wiki').join('|'),
    'format': 'json',
  }));
  final e = (res?['entities'] as Map?)?[qid] as Map?;
  if (e == null || e.containsKey('missing')) return null;
  final labels = <String, String>{
    for (final entry in ((e['labels'] as Map?) ?? const {}).entries)
      entry.key.toString(): (entry.value as Map)['value'].toString(),
  };
  final sitelinks = <String, String>{};
  for (final entry in ((e['sitelinks'] as Map?) ?? const {}).entries) {
    final site = entry.key.toString();
    if (!site.endsWith('wiki')) continue;
    final lang = site.substring(0, site.length - 4);
    if (appLanguages.contains(lang)) {
      sitelinks[lang] = (entry.value as Map)['title'].toString();
    }
  }
  return _Entity(labels, sitelinks);
}

/// Makalenin giriş bölümü, düz metin.
Future<String?> _intro(String lang, String title) async {
  final data = await _api(lang, {
    'action': 'query',
    'prop': 'extracts',
    'exintro': '1',
    'explaintext': '1',
    'redirects': '1',
    'titles': title,
  });
  final pages = (data?['query']?['pages'] as Map?)?.values;
  if (pages == null || pages.isEmpty) return null;
  final text = (pages.first as Map)['extract']?.toString().trim();
  return (text == null || text.isEmpty) ? null : text;
}

Future<Map<String, dynamic>?> _api(String lang, Map<String, String> params) =>
    _get(Uri.https('$lang.wikipedia.org', '/w/api.php',
        {...params, 'format': 'json', 'formatversion': '1', 'maxlag': '5'}));

Future<Map<String, dynamic>?> _get(Uri uri) async {
  for (var attempt = 0; attempt < 3; attempt++) {
    try {
      final res = await http
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final body = jsonDecode(utf8.decode(res.bodyBytes));
        // maxlag: sunucu yoğunsa bekle ve tekrar dene
        if (body is Map && (body['error'] as Map?)?['code'] == 'maxlag') {
          await Future.delayed(const Duration(seconds: 5));
          continue;
        }
        return body as Map<String, dynamic>;
      }
      if (res.statusCode == 429 || res.statusCode >= 500) {
        await Future.delayed(Duration(seconds: 5 * (attempt + 1)));
        continue;
      }
      return null;
    } catch (_) {
      await Future.delayed(Duration(seconds: 3 * (attempt + 1)));
    }
  }
  return null;
}

// ── Supabase ─────────────────────────────────────────────────────

Future<List<Map<String, dynamic>>> _fetchAll(
    String url, Map<String, String> headers) async {
  const page = 1000;
  final out = <Map<String, dynamic>>[];
  for (var from = 0;; from += page) {
    final res = await http.get(Uri.parse(url), headers: {
      ...headers,
      'Range-Unit': 'items',
      'Range': '$from-${from + page - 1}',
    });
    if (res.statusCode != 200 && res.statusCode != 206) {
      stderr.writeln('Okuma hatası: ${res.statusCode} ${res.body}');
      exit(1);
    }
    final chunk = (jsonDecode(utf8.decode(res.bodyBytes)) as List)
        .cast<Map<String, dynamic>>();
    out.addAll(chunk);
    if (chunk.length < page) return out;
  }
}

Future<void> _upsertTranslations(String base, Map<String, String> headers,
    List<Map<String, dynamic>> rows) async {
  final res = await http.post(
    Uri.parse('$base/rest/v1/place_translations?on_conflict=place_id,lang'),
    headers: {
      ...headers,
      'Prefer': 'resolution=merge-duplicates,return=minimal',
    },
    body: jsonEncode(rows),
  );
  if (res.statusCode >= 300) {
    throw 'çeviri yazılamadı: ${res.statusCode} ${res.body}';
  }
}

Future<void> _patchPlace(String base, Map<String, String> headers, String id,
    Map<String, dynamic> patch) async {
  final res = await http.patch(
    Uri.parse('$base/rest/v1/places?id=eq.$id'),
    headers: {...headers, 'Prefer': 'return=minimal'},
    body: jsonEncode(patch),
  );
  if (res.statusCode >= 300) {
    throw 'mekan güncellenemedi: ${res.statusCode} ${res.body}';
  }
}

