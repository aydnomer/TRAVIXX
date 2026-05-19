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
}
