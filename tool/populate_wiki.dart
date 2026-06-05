// Tek seferlik toplu doldurma script'i.
//
// Tüm mekanlar için Wikipedia'dan detaylı tarihçe + fotoğraf çekip
// Supabase'deki `places` tablosuna yazar:
//   - description  ← detaylı tarihçe (Wikipedia tam makale metni)
//   - images       ← mekan fotoğrafları; yoksa ŞEHİR fotoğrafı (fallback)
// Tarayıcı dışında çalıştığı için CORS yok; yeni kolon/SQL gerekmez.
//
// ── Çalıştırma (PowerShell, proje klasöründe) ──
//   $env:SUPABASE_URL="https://xxxx.supabase.co"
//   $env:SUPABASE_KEY="<anon veya service_role key>"
//   dart run tool/populate_wiki.dart
//
// Bayraklar:
//   --force   description/images zaten dolu olanları da yeniden çek

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:travixx/core/utils/wikipedia_service.dart';

Future<void> main(List<String> args) async {
  final url = Platform.environment['SUPABASE_URL'];
  final key =
      Platform.environment['SUPABASE_KEY'] ?? Platform.environment['SUPABASE_SERVICE_KEY'];
  final force = args.contains('--force');

  if (url == null || key == null) {
    stderr.writeln('HATA: SUPABASE_URL ve SUPABASE_KEY ortam değişkenleri gerekli.');
    exit(1);
  }

  final base = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  final headers = {
    'apikey': key,
    'Authorization': 'Bearer $key',
    'Content-Type': 'application/json',
    'Prefer': 'return=minimal',
  };

  // Şehirleri yükle (foto fallback için: id → {name, image_url})
  stdout.writeln('Şehirler yükleniyor...');
  final cityRes = await http.get(
    Uri.parse('$base/rest/v1/cities?select=id,name,name_en,image_url'),
    headers: headers,
  );
  final cities = <String, Map<String, dynamic>>{};
  if (cityRes.statusCode == 200) {
    for (final c in jsonDecode(cityRes.body) as List) {
      cities[c['id'].toString()] = c as Map<String, dynamic>;
    }
  }
  final cityPhotoCache = <String, List<String>>{};

  Future<List<String>> cityPhotos(String? cityId) async {
    if (cityId == null) return const [];
    if (cityPhotoCache.containsKey(cityId)) return cityPhotoCache[cityId]!;
    final city = cities[cityId];
    final out = <String>[];
    final imgUrl = (city?['image_url'] as String?)?.trim();
    if (imgUrl != null && imgUrl.isNotEmpty) {
      out.add(imgUrl);
    } else if (city != null) {
      final m = await WikipediaService.fetchPlaceMedia(
        name: city['name'] as String? ?? '',
        nameEn: city['name_en'] as String?,
        maxImages: 3,
      );
      out.addAll(m.images);
    }
    cityPhotoCache[cityId] = out;
    return out;
  }

  // Mekanları çek
  stdout.writeln('Mekanlar çekiliyor...');
  final listRes = await http.get(
    Uri.parse('$base/rest/v1/places?select=id,name,name_en,city_id,description,images'),
    headers: headers,
  );
  if (listRes.statusCode != 200) {
    stderr.writeln('Mekanlar çekilemedi: ${listRes.statusCode} ${listRes.body}');
    exit(1);
  }
  final places = (jsonDecode(listRes.body) as List).cast<Map<String, dynamic>>();
  stdout.writeln('${places.length} mekan bulundu.\n');

  var updated = 0, withCityPhoto = 0, noPhoto = 0, failed = 0;

  for (var i = 0; i < places.length; i++) {
    final p = places[i];
    final id = p['id'];
    final name = (p['name'] as String?)?.trim() ?? '';
    final nameEn = (p['name_en'] as String?)?.trim();
    final cityId = p['city_id']?.toString();
    final curDesc = (p['description'] as String?)?.trim() ?? '';
    final curImages = (p['images'] is List) ? (p['images'] as List) : const [];
    final prefix = '[${i + 1}/${places.length}] $name';

    if (name.isEmpty) continue;
    if (!force && curDesc.length > 200 && curImages.isNotEmpty) {
      stdout.writeln('$prefix → atlandı (zaten dolu)');
      continue;
    }

    try {
      final media = await WikipediaService.fetchPlaceMedia(
        name: name,
        nameEn: (nameEn != null && nameEn.isNotEmpty) ? nameEn : null,
        maxImages: 6,
      );

      final body = <String, dynamic>{};

      // Tarihçe → description (mevcut kısa açıklamadan uzunsa güncelle)
      final hist = media.extract?.trim() ?? '';
      if (hist.length > 200 && hist.length > curDesc.length) {
        body['description'] = hist;
      }

      // Fotoğraf: mekan foto'su; yoksa şehir foto'su
      var imgs = media.images;
      var usedCity = false;
      if (imgs.isEmpty && curImages.isEmpty) {
        imgs = await cityPhotos(cityId);
        usedCity = imgs.isNotEmpty;
      }
      if (imgs.isNotEmpty && (curImages.isEmpty || force)) {
        body['images'] = imgs;
      }

      if (body.isEmpty) {
        noPhoto++;
        stdout.writeln('$prefix → veri bulunamadı');
        continue;
      }

      final patch = await http.patch(
        Uri.parse('$base/rest/v1/places?id=eq.$id'),
        headers: headers,
        body: jsonEncode(body),
      );
      if (patch.statusCode >= 200 && patch.statusCode < 300) {
        updated++;
        if (usedCity) withCityPhoto++;
        final bits = [
          if (body.containsKey('description')) 'tarihçe',
          if (body.containsKey('images'))
            '${(body['images'] as List).length} foto${usedCity ? " (şehir)" : ""}',
        ].join(' + ');
        stdout.writeln('$prefix → $bits');
      } else {
        failed++;
        stdout.writeln('$prefix → yazma hatası: ${patch.statusCode}');
      }
    } catch (e) {
      failed++;
      stdout.writeln('$prefix → hata: $e');
    }

    await Future.delayed(const Duration(milliseconds: 250));
  }

  stdout.writeln('\n── Bitti ──');
  stdout.writeln(
      'Güncellenen: $updated (şehir foto: $withCityPhoto) | Verisiz: $noPhoto | Hata: $failed');
}
