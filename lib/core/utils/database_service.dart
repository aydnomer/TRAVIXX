import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/cities/city_model.dart';
import '../../features/places/place_model.dart';

class DatabaseService {
  static final _supabase = Supabase.instance.client;

  static Future<List<City>> getCities() async {
    final response = await _supabase
        .from('cities')
        .select()
        .order('name', ascending: true);
    return (response as List)
        .map((json) => City.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Şehrin tüm mekanları. Sunucu tek seferde en çok 1000 satır döndüğü
  /// için sayfa sayfa çekilir (OSM aktarımından sonra büyük iller aşabilir).
  static Future<List<Place>> getPlacesByCity(String cityId) async {
    const page = 1000;
    final all = <Place>[];
    for (var from = 0;; from += page) {
      final response = await _supabase
          .from('places')
          .select()
          .eq('city_id', cityId)
          .order('rating', ascending: false)
          .order('id')
          .range(from, from + page - 1);
      final chunk = _toPlaces(response);
      all.addAll(chunk);
      if (chunk.length < page) return all;
    }
  }

  static List<Place> _toPlaces(dynamic response) => (response as List)
      .map((json) => Place.fromJson(json as Map<String, dynamic>))
      .toList();

  /// Bir noktaya en yakın mekanlar (sunucuda `nearby_places` RPC).
  /// [categories] verilirse yalnızca o kategoriler döner.
  static Future<List<Place>> getNearbyPlaces(
    double lat,
    double lng, {
    int limit = 50,
    List<String>? categories,
    double radiusKm = 300,
  }) async {
    final response = await _supabase.rpc('nearby_places', params: {
      'p_lat': lat,
      'p_lng': lng,
      'p_limit': limit,
      'p_categories': categories,
      'p_radius_km': radiusKm,
    });
    return _toPlaces(response);
  }

  /// Konum yokken ana sayfa için: öne çıkanlar, sonra en yüksek puanlılar.
  static Future<List<Place>> getPopularPlaces({int limit = 50}) async {
    final response = await _supabase
        .from('places')
        .select()
        .order('is_featured', ascending: false)
        .order('rating', ascending: false)
        .limit(limit);
    return _toPlaces(response);
  }

  /// Harita görünümündeki mekanlar (dikdörtgen alan).
  static Future<List<Place>> getPlacesInBounds({
    required double south,
    required double west,
    required double north,
    required double east,
    int limit = 400,
  }) async {
    final response = await _supabase
        .from('places')
        .select()
        .gte('latitude', south)
        .lte('latitude', north)
        .gte('longitude', west)
        .lte('longitude', east)
        .order('is_featured', ascending: false)
        .order('rating', ascending: false)
        .limit(limit);
    return _toPlaces(response);
  }

  /// Kategorisi [categories]'den biri olan ya da adında [keywords]'den biri
  /// geçen mekanlar, puana göre (ruh hâli ekranı için).
  static Future<List<Place>> getPlacesMatching({
    List<String> categories = const [],
    List<String> keywords = const [],
    int limit = 300,
  }) async {
    String clean(String v) => v.replaceAll(RegExp(r'[,()%*\\"]'), ' ').trim();
    final filters = [
      if (categories.isNotEmpty)
        'category.in.(${categories.map(clean).map((c) => '"$c"').join(',')})',
      for (final k in keywords.map(clean).where((k) => k.isNotEmpty))
        'name.ilike.*$k*',
    ];
    if (filters.isEmpty) return const [];
    final response = await _supabase
        .from('places')
        .select()
        .or(filters.join(','))
        .order('rating', ascending: false)
        .limit(limit);
    return _toPlaces(response);
  }

  static Future<List<Place>> searchPlaces(String query,
      {int limit = 100}) async {
    // PostgREST `or` filtresinde virgül, parantez ve joker karakterler
    // sözdizimini bozar; kullanıcı girdisinden temizlenir.
    final q = query.replaceAll(RegExp(r'[,()%*\\"]'), ' ').trim();
    if (q.isEmpty) return const [];
    final response = await _supabase
        .from('places')
        .select()
        .or('name.ilike.%$q%,name_en.ilike.%$q%')
        .order('rating', ascending: false)
        .limit(limit);
    return (response as List)
        .map((json) => Place.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<City?> getCityById(String cityId) async {
    try {
      final response = await _supabase
          .from('cities')
          .select()
          .eq('id', cityId)
          .maybeSingle();
      if (response == null) return null;
      return City.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  static Future<Place?> getPlaceById(String placeId) async {
    final response = await _supabase
        .from('places')
        .select()
        .eq('id', placeId)
        .maybeSingle();
    if (response == null) return null;
    return Place.fromJson(response);
  }

  /// Kullanıcının favori mekanlarını döner (places ile join).
  /// userId null veya boş ise boş liste döner (giriş yapılmamış demek).
  /// Birden çok id ile mekan listesi getir (order verilen liste sırası)
  static Future<List<Place>> getPlacesByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    try {
      final response =
          await _supabase.from('places').select().inFilter('id', ids);
      final list = (response as List)
          .map((r) => Place.fromJson(r as Map<String, dynamic>))
          .toList();
      // İstenen sıraya göre yeniden düzenle
      final byId = {for (final p in list) p.id: p};
      return ids.map((id) => byId[id]).whereType<Place>().toList();
    } catch (_) {
      return const [];
    }
  }

  /// En yüksek puanlı mekanlar (top rated)
  static Future<List<Place>> getTopRated({int limit = 50, double minRating = 4.5}) async {
    try {
      final response = await _supabase
          .from('places')
          .select()
          .gte('rating', minRating)
          .order('rating', ascending: false)
          .limit(limit);
      return (response as List)
          .map((r) => Place.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<List<Place>> getFavorites(String? userId) async {
    if (userId == null || userId.isEmpty) return const [];
    final response = await _supabase
        .from('favorites')
        .select('place_id, places(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (response as List)
        .where((row) => row['places'] != null)
        .map((row) => Place.fromJson(row['places'] as Map<String, dynamic>))
        .toList();
  }
}
