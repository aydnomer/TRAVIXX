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
