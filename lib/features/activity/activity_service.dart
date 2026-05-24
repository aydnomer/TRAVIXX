import 'package:supabase_flutter/supabase_flutter.dart';

/// Kullanıcının son aktivitelerini birleştirir:
/// - visits (gamification tablosu)
/// - favorites (eklenen favoriler)
/// - reviews (yazılan yorumlar)
class ActivityService {
  static final _supabase = Supabase.instance.client;

  /// Son 30 aktivite, en yenidan en eskiye
  static Future<List<ActivityItem>> getMyActivity() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return const [];

    final items = <ActivityItem>[];

    try {
      // Son 15 ziyaret
      final visits = await _supabase
          .from('visits')
          .select('id, visited_at, places(id, name, emoji)')
          .eq('user_id', user.id)
          .order('visited_at', ascending: false)
          .limit(15);
      for (final v in (visits as List)) {
        final p = (v as Map)['places'];
        if (p is Map) {
          items.add(ActivityItem(
            type: 'visit',
            time: DateTime.tryParse(v['visited_at'] as String? ?? '') ??
                DateTime.now(),
            placeId: p['id'] as String?,
            placeName: p['name'] as String? ?? '',
            placeEmoji: p['emoji'] as String? ?? '📍',
          ));
        }
      }
    } catch (_) {}

    try {
      // Son 10 favori
      final favs = await _supabase
          .from('favorites')
          .select('id, created_at, places(id, name, emoji)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(10);
      for (final f in (favs as List)) {
        final p = (f as Map)['places'];
        if (p is Map) {
          items.add(ActivityItem(
            type: 'favorite',
            time: DateTime.tryParse(f['created_at'] as String? ?? '') ??
                DateTime.now(),
            placeId: p['id'] as String?,
            placeName: p['name'] as String? ?? '',
            placeEmoji: p['emoji'] as String? ?? '❤️',
          ));
        }
      }
    } catch (_) {}

    try {
      // Son 10 yorum
      final reviews = await _supabase
          .from('reviews')
          .select('id, created_at, rating, places(id, name, emoji)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(10);
      for (final r in (reviews as List)) {
        final p = (r as Map)['places'];
        if (p is Map) {
          items.add(ActivityItem(
            type: 'review',
            time: DateTime.tryParse(r['created_at'] as String? ?? '') ??
                DateTime.now(),
            placeId: p['id'] as String?,
            placeName: p['name'] as String? ?? '',
            placeEmoji: p['emoji'] as String? ?? '⭐',
            rating: (r['rating'] as num?)?.toInt(),
          ));
        }
      }
    } catch (_) {}

    // Hepsini zaman sırasına göre birleştir
    items.sort((a, b) => b.time.compareTo(a.time));
    return items.take(30).toList();
  }
}

class ActivityItem {
  final String type; // visit | favorite | review
  final DateTime time;
  final String? placeId;
  final String placeName;
  final String placeEmoji;
  final int? rating;

  const ActivityItem({
    required this.type,
    required this.time,
    this.placeId,
    required this.placeName,
    required this.placeEmoji,
    this.rating,
  });

  String get typeEmoji {
    switch (type) {
      case 'visit':
        return '👣';
      case 'favorite':
        return '❤️';
      case 'review':
        return '⭐';
      default:
        return '📍';
    }
  }

  String get typeLabel {
    switch (type) {
      case 'visit':
        return 'ziyaret edildi';
      case 'favorite':
        return 'favorilere eklendi';
      case 'review':
        return 'yorum yapıldı';
      default:
        return '';
    }
  }
}
