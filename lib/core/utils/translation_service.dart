import 'package:supabase_flutter/supabase_flutter.dart';

/// Mekan metninin bir dildeki karşılığı (`place_translations` tablosu,
/// Wikipedia dil sürümlerinden doldurulur).
class PlaceText {
  final String lang;
  final String? name;
  final String? description;
  final String? history;
  final String? sourceUrl;

  const PlaceText({
    required this.lang,
    this.name,
    this.description,
    this.history,
    this.sourceUrl,
  });

  factory PlaceText.fromJson(Map<String, dynamic> json) {
    String? nz(Object? v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    return PlaceText(
      lang: json['lang'] as String,
      name: nz(json['name']),
      description: nz(json['description']),
      history: nz(json['history']),
      sourceUrl: nz(json['source_url']),
    );
  }
}

class TranslationService {
  static final Map<String, PlaceText?> _cache = {};

  /// Mekanın [lang] dilindeki metni; yoksa null.
  /// Tablo henüz yoksa ya da ağ hatasında da null döner (uygulama eski
  /// TR/EN metne düşer).
  static Future<PlaceText?> forPlace(String placeId, String lang) async {
    final key = '$placeId:$lang';
    if (_cache.containsKey(key)) return _cache[key];
    try {
      final row = await Supabase.instance.client
          .from('place_translations')
          .select('lang,name,description,history,source_url')
          .eq('place_id', placeId)
          .eq('lang', lang)
          .maybeSingle();
      final text = row == null ? null : PlaceText.fromJson(row);
      _cache[key] = text;
      return text;
    } catch (_) {
      return null;
    }
  }
}
