// Tek seferlik toplu doldurma script'i.
//
// Tüm mekanlar için Wikipedia'dan detaylı tarihçe + birden fazla fotoğraf
// çekip Supabase'deki `places` tablosuna (history + images) yazar.
// Tarayıcı dışında çalıştığı için CORS sorunu YOKTUR.
//
// ── Önce SQL'i çalıştır (Supabase SQL Editor) ──
//   supabase/history_column.sql
//
// ── Çalıştırma ──
//   1) SUPABASE_URL ve SUPABASE_SERVICE_KEY ortam değişkenlerini ayarla
//      (service_role key — Supabase > Settings > API > service_role secret)
//   2) dart run tool/populate_wiki.dart
//
//   PowerShell örneği:
//     $env:SUPABASE_URL="https://xxxx.supabase.co"
//     $env:SUPABASE_SERVICE_KEY="eyJ..."
//     dart run tool/populate_wiki.dart
//
// Bayraklar:
//   --force   Zaten history/images olanları da yeniden çek (varsayılan: atla)

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:travixx/core/utils/wikipedia_service.dart';

Future<void> main(List<String> args) async {
  final url = Platform.environment['SUPABASE_URL'];
  final key = Platform.environment['SUPABASE_SERVICE_KEY'];
  final force = args.contains('--force');

  if (url == null || key == null) {
    stderr.writeln(
        'HATA: SUPABASE_URL ve SUPABASE_SERVICE_KEY ortam değişkenleri gerekli.');
    exit(1);
  }

  final base = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  final headers = {
    'apikey': key,
    'Authorization': 'Bearer $key',
    'Content-Type': 'application/json',
    'Prefer': 'return=minimal',
  };

  // 1) Tüm mekanları çek
  stdout.writeln('Mekanlar çekiliyor...');
  final listRes = await http.get(
    Uri.parse('$base/rest/v1/places?select=id,name,name_en,images,history'),
    headers: headers,
  );
  if (listRes.statusCode != 200) {
    stderr.writeln('Mekanlar çekilemedi: ${listRes.statusCode} ${listRes.body}');
    exit(1);
  }
  final places = (jsonDecode(listRes.body) as List).cast<Map<String, dynamic>>();
  stdout.writeln('${places.length} mekan bulundu.\n');

  var updated = 0, skipped = 0, failed = 0;

  for (var i = 0; i < places.length; i++) {
    final p = places[i];
    final id = p['id'];
    final name = (p['name'] as String?)?.trim() ?? '';
    final nameEn = (p['name_en'] as String?)?.trim();
    final hasHistory = ((p['history'] as String?)?.trim().length ?? 0) > 100;
    final curImages = (p['images'] is List) ? (p['images'] as List) : const [];
    final hasImages = curImages.isNotEmpty;
    final prefix = '[${i + 1}/${places.length}] $name';

    if (!force && hasHistory && hasImages) {
      skipped++;
      stdout.writeln('$prefix → atlandı (zaten dolu)');
      continue;
    }
    if (name.isEmpty) {
      skipped++;
      continue;
    }

    try {
      final media = await WikipediaService.fetchPlaceMedia(
        name: name,
        nameEn: (nameEn != null && nameEn.isNotEmpty) ? nameEn : null,
        maxImages: 6,
      );

      final body = <String, dynamic>{};
      if ((media.extract?.trim().length ?? 0) > 100) {
        body['history'] = media.extract!.trim();
      }
      if (media.images.isNotEmpty && (!hasImages || force)) {
        body['images'] = media.images;
      }

      if (body.isEmpty) {
        failed++;
        stdout.writeln('$prefix → Wikipedia\'da bulunamadı');
      } else {
        final patch = await http.patch(
          Uri.parse('$base/rest/v1/places?id=eq.$id'),
          headers: headers,
          body: jsonEncode(body),
        );
        if (patch.statusCode >= 200 && patch.statusCode < 300) {
          updated++;
          final bits = [
            if (body.containsKey('history')) 'tarihçe',
            if (body.containsKey('images')) '${media.images.length} foto',
          ].join(' + ');
          stdout.writeln('$prefix → güncellendi ($bits)');
        } else {
          failed++;
          stdout.writeln('$prefix → yazma hatası: ${patch.statusCode}');
        }
      }
    } catch (e) {
      failed++;
      stdout.writeln('$prefix → hata: $e');
    }

    // Wikipedia'ya nazik ol — kısa bekleme
    await Future.delayed(const Duration(milliseconds: 300));
  }

  stdout.writeln('\n── Bitti ──');
  stdout.writeln('Güncellenen: $updated | Atlanan: $skipped | Başarısız: $failed');
}
