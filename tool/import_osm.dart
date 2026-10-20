// OpenStreetMap'ten Türkiye geneli turistik mekan aktarımı.
//
// Her il için Overpass API'ye sorgu atar; plajları, müzeleri, antik
// kentleri, kaleleri, şelaleleri, mağaraları, kanyonları, kaplıcaları,
// milli parkları, seyir noktalarını vb. `places` tablosuna yazar.
//
// - OSM kayıtları `osm_ref` ("node/123") ile tekilleşir; tekrar
//   çalıştırınca yenisi eklenir, var olan güncellenir.
// - Elle girilmiş (source = 'travixx') mekanlara dokunulmaz; aynı yerin
//   OSM kopyası (500 m içinde, ortak ad kelimesi) atlanır.
// - Açıklama/tarihçe/foto yazılmaz (onları detay sayfası Wikipedia'dan
//   çeker, populate_wiki.dart doldurur), elle düzeltmeler ezilmez.
//
// Veri © OpenStreetMap katkıcıları, ODbL lisansı. Uygulamada atıf gösterilir.
//
// ── Çalıştırma ──
// GitHub Actions: "Import places (OSM)" iş akışı (elle veya ayda bir).
// Yerelde:
//   SUPABASE_URL=https://xxxx.supabase.co \
//   SUPABASE_SERVICE_ROLE_KEY=<service_role> \
//   dart run tool/import_osm.dart [--dry-run] [--only=34,07]
//
// service_role anahtarı RLS'i aşar: asla repoya koyma, uygulamaya gömme.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'osm/osm_mapper.dart';

const _overpassEndpoints = [
  'https://overpass-api.de/api/interpreter',
  'https://overpass.kumi.systems/api/interpreter',
];
const _userAgent =
    'TravixxImporter/1.0 (https://github.com/aydnomer/TRAVIXX)';

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final onlyArg = args.firstWhere((a) => a.startsWith('--only='),
      orElse: () => '');
  final only = onlyArg.isEmpty
      ? null
      : onlyArg
          .substring(7)
          .split(',')
          .map((s) => s.trim().padLeft(2, '0'))
          .where((s) => s.isNotEmpty)
          .toSet();

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

  // Şehirler: il adı → city_id
  final citiesRes = await http.get(
      Uri.parse('$base/rest/v1/cities?select=id,name'),
      headers: headers);
  if (citiesRes.statusCode != 200) {
    stderr.writeln('Şehirler okunamadı: ${citiesRes.statusCode} ${citiesRes.body}');
    exit(1);
  }
  final cityIdByProvince = <String, String>{};
  final cityRows = (jsonDecode(citiesRes.body) as List).cast<Map>();
  provinces.forEach((plate, provinceName) {
    final f = fold(provinceName);
    for (final c in cityRows) {
      final n = fold(c['name'].toString());
      // "İçel (Mersin)" gibi parantezli adları da yakala
      if (n == f || n.contains('($f)')) {
        cityIdByProvince[plate] = c['id'].toString();
        break;
      }
    }
  });
  final missing = provinces.keys.where((k) => !cityIdByProvince.containsKey(k));
  if (missing.isNotEmpty) {
    stderr.writeln('UYARI: eşleşmeyen iller: ${missing.map((k) => provinces[k]).join(', ')}');
  }

  // Elle girilmiş mekanlar (tekrar kontrolü için)
  final curated = await _fetchAll(
    '$base/rest/v1/places?select=city_id,name,name_en,latitude,longitude'
    '&source=eq.travixx',
    headers,
  );
  final curatedByCity = <String, List<Map<String, dynamic>>>{};
  for (final p in curated) {
    curatedByCity.putIfAbsent(p['city_id'].toString(), () => []).add(p);
  }
  stdout.writeln('${cityIdByProvince.length} il, ${curated.length} elle girilmiş mekan.\n');

  var total = 0, skippedDup = 0, failedProvinces = <String>[];
  final countsByCategory = <String, int>{};

  for (final entry in provinces.entries) {
    final plate = entry.key;
    if (only != null && !only.contains(plate)) continue;
    final cityId = cityIdByProvince[plate];
    if (cityId == null) continue;

    stdout.write('[$plate] ${entry.value} … ');
    final elements = await _overpass(overpassQuery(plate));
    if (elements == null) {
      stdout.writeln('Overpass hatası, atlandı');
      failedProvinces.add(entry.value);
      continue;
    }

    final rows = <Map<String, dynamic>>[];
    final existing = curatedByCity[cityId] ?? const [];
    for (final el in elements) {
      final row = toPlaceRow(el as Map<String, dynamic>, cityId);
      if (row == null) continue;
      if (isDuplicateOf(row, existing) || isDuplicateOf(row, rows, maxKm: 0.2)) {
        skippedDup++;
        continue;
      }
      rows.add(row);
    }

    for (final r in rows) {
      final c = r['category'] as String;
      countsByCategory[c] = (countsByCategory[c] ?? 0) + 1;
    }
    total += rows.length;

    if (dryRun || rows.isEmpty) {
      stdout.writeln('${rows.length} mekan${dryRun ? ' (deneme)' : ''}');
    } else {
      final ok = await _upsert(base, headers, rows);
      stdout.writeln(ok ? '${rows.length} mekan yazıldı' : 'YAZMA HATASI');
      if (!ok) failedProvinces.add(entry.value);
    }

    // Overpass'a nazik ol
    await Future.delayed(const Duration(seconds: 5));
  }

  stdout.writeln('\n── Bitti ──');
  stdout.writeln('Toplam: $total mekan | tekrar olduğu için atlanan: $skippedDup');
  countsByCategory.forEach((k, v) => stdout.writeln('  $k: $v'));
  if (failedProvinces.isNotEmpty) {
    stdout.writeln('Hata veren iller: ${failedProvinces.join(', ')}');
    exitCode = 2;
  }
}

Future<List?> _overpass(String query) async {
  for (var attempt = 0; attempt < 3; attempt++) {
    final endpoint = _overpassEndpoints[attempt % _overpassEndpoints.length];
    try {
      final res = await http
          .post(Uri.parse(endpoint),
              headers: {'User-Agent': _userAgent},
              body: {'data': query})
          .timeout(const Duration(minutes: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        return (data['elements'] as List?) ?? const [];
      }
      stderr.writeln('Overpass ${res.statusCode} ($endpoint)');
    } catch (e) {
      stderr.writeln('Overpass hata: $e');
    }
    await Future.delayed(Duration(seconds: 20 * (attempt + 1)));
  }
  return null;
}

Future<bool> _upsert(String base, Map<String, String> headers,
    List<Map<String, dynamic>> rows) async {
  for (var i = 0; i < rows.length; i += 500) {
    final batch = rows.sublist(i, (i + 500).clamp(0, rows.length));
    final res = await http.post(
      Uri.parse('$base/rest/v1/places?on_conflict=osm_ref'),
      headers: {
        ...headers,
        'Prefer': 'resolution=merge-duplicates,return=minimal',
      },
      body: jsonEncode(batch),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      stderr.writeln('Yazma hatası ${res.statusCode}: ${res.body}');
      return false;
    }
  }
  return true;
}

/// PostgREST sayfalaması (1000 satır sınırını aşmak için).
Future<List<Map<String, dynamic>>> _fetchAll(
    String url, Map<String, String> headers) async {
  final out = <Map<String, dynamic>>[];
  const page = 1000;
  for (var from = 0;; from += page) {
    final res = await http.get(Uri.parse(url), headers: {
      ...headers,
      'Range-Unit': 'items',
      'Range': '$from-${from + page - 1}',
    });
    if (res.statusCode != 200 && res.statusCode != 206) {
      throw Exception('Okuma hatası ${res.statusCode}: ${res.body}');
    }
    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    out.addAll(list);
    if (list.length < page) break;
  }
  return out;
}
