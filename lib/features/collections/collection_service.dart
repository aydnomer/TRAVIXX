import 'package:supabase_flutter/supabase_flutter.dart';

import '../places/place_model.dart';
import 'collection_model.dart';

/// Tematik koleksiyon servisi.
class CollectionService {
  static final _supabase = Supabase.instance.client;

  /// Tüm aktif koleksiyonları döner (display_order'a göre sıralı).
  /// place_count'u o anda hesaplar (eager).
  static Future<List<PlaceCollection>> getCollections() async {
    try {
      final response = await _supabase
          .from('collections')
          .select('*, collection_places(count)')
          .order('display_order', ascending: true);

      final list = response as List;
      return list.map((row) {
        final r = row as Map<String, dynamic>;
        final counts = r['collection_places'] as List?;
        final count = (counts != null && counts.isNotEmpty)
            ? ((counts.first as Map)['count'] as num).toInt()
            : 0;
        return PlaceCollection.fromJson({...r, 'place_count': count});
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Tek bir koleksiyonu döner
  static Future<PlaceCollection?> getCollection(String id) async {
    try {
      final response = await _supabase
          .from('collections')
          .select('*, collection_places(count)')
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      final counts = response['collection_places'] as List?;
      final count = (counts != null && counts.isNotEmpty)
          ? ((counts.first as Map)['count'] as num).toInt()
          : 0;
      return PlaceCollection.fromJson({...response, 'place_count': count});
    } catch (_) {
      return null;
    }
  }

  /// Bir koleksiyondaki mekanları döner (display_order'a göre)
  static Future<List<Place>> getPlacesInCollection(String collectionId) async {
    try {
      final response = await _supabase
          .from('collection_places')
          .select('display_order, places(*)')
          .eq('collection_id', collectionId)
          .order('display_order', ascending: true);

      final list = response as List;
      return list
          .where((r) => r['places'] != null)
          .map((r) => Place.fromJson(r['places'] as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
