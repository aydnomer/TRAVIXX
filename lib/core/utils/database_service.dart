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

  static Future<List<Place>> getPlacesByCity(String cityId) async {
    final response = await _supabase
        .from('places')
        .select()
        .eq('city_id', cityId)
        .order('rating', ascending: false);
    return (response as List)
        .map((json) => Place.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Place>> getAllPlaces() async {
    final response = await _supabase
        .from('places')
        .select()
        .order('rating', ascending: false);
    return (response as List)
        .map((json) => Place.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Place>> searchPlaces(String query) async {
    final response = await _supabase
        .from('places')
        .select()
        .or('name.ilike.%$query%,name_en.ilike.%$query%')
        .order('rating', ascending: false);
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
