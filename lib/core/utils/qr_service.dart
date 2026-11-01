import 'package:supabase_flutter/supabase_flutter.dart';

/// QR kod çözümleme ve link üretme.
///
/// Mekanlara basılan QR'ın içeriği bir web linkidir:
///   `https://aydnomer.github.io/TRAVIXX/#/qr/KOD`
/// Böylece uygulaması olmayan turist telefon kamerasıyla okutsa da web
/// sürümü açılır. Uygulama içi tarayıcı da aynı linki çözer.
///
/// KOD şunlardan biri olabilir:
///   - mekanın id'si (uuid) → doğrudan mekan açılır
///   - qr_codes.qr_data değeri → tablodan mekan bulunur
class QrService {
  static const String webBase = 'https://aydnomer.github.io/TRAVIXX/';

  static final _uuid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false);

  /// Bir mekan için basılacak QR linki.
  static String linkForPlace(String placeId) => '$webBase#/qr/$placeId';

  /// QR'dan okunan ham metinden kodu ayıklar.
  /// Link ise `/qr/KOD` veya `/place/ID` kısmını alır; değilse metnin kendisi.
  static String extractCode(String raw) {
    final value = raw.trim();
    final m = RegExp(r'/(?:qr|place)/([^/?#\s]+)').firstMatch(value);
    if (m != null) return Uri.decodeComponent(m.group(1)!);
    return value;
  }

  /// Ham QR içeriğini mekan id'sine çevirir. Bulunamazsa null.
  static Future<String?> resolvePlaceId(String raw) async {
    final code = extractCode(raw);
    if (code.isEmpty) return null;
    final db = Supabase.instance.client;

    if (_uuid.hasMatch(code)) {
      final place = await db
          .from('places')
          .select('id')
          .eq('id', code)
          .maybeSingle();
      if (place != null) {
        _countScan(code);
        return place['id'] as String;
      }
    }

    // qr_codes tablosunda hem ayıklanan kodu hem ham metni dene
    for (final candidate in {code, raw.trim()}) {
      final row = await db
          .from('qr_codes')
          .select('place_id')
          .eq('qr_data', candidate)
          .maybeSingle();
      final placeId = row?['place_id'] as String?;
      if (placeId != null) {
        _countScan(candidate);
        return placeId;
      }
    }
    return null;
  }

  /// Tarama sayacını artırır (best-effort). Sayaç, veritabanındaki
  /// `increment_qr_scan` fonksiyonuyla atomik olarak artırılır.
  static void _countScan(String code) {
    Supabase.instance.client
        .rpc('increment_qr_scan', params: {'p_code': code})
        .then((_) {}, onError: (_) {});
  }
}
