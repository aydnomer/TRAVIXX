import 'package:supabase_flutter/supabase_flutter.dart';

/// Mekan yorumları servisi.
///
/// Supabase tablosu (README'de SQL'i var):
///   reviews(id, place_id, user_id, rating, comment, user_name, photos,
///           created_at, updated_at)
///   UNIQUE(place_id, user_id) — bir kullanıcı bir mekana bir yorum
///
/// RLS:
///   - Herkes okuyabilir (yorumlar public)
///   - Sadece sahibi insert/update/delete edebilir
class ReviewService {
  static final _supabase = Supabase.instance.client;

  /// Yorum başına en çok foto (veritabanı kısıtıyla aynı).
  static const maxPhotos = 4;

  /// Bir mekanın yorumları (yeniden eskiye)
  static Future<List<Review>> getReviews(String placeId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('place_id', placeId)
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List)
          .map((r) => Review.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Kullanıcının bu mekana zaten verdiği yorum (varsa)
  static Future<Review?> getMyReview(String placeId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('place_id', placeId)
          .eq('user_id', user.id)
          .maybeSingle();
      if (response == null) return null;
      return Review.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  /// Yorum kaydet (yeni veya update). Başarılıysa kaydedilen yorum dönülür.
  static Future<Review?> upsert({
    required String placeId,
    required int rating,
    required String comment,
    List<String> photos = const [],
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    if (rating < 1 || rating > 5) return null;

    try {
      final response = await _supabase
          .from('reviews')
          .upsert(
            {
              'place_id': placeId,
              'user_id': user.id,
              'rating': rating,
              'comment': comment.trim(),
              'photos': photos.take(maxPhotos).toList(),
              // E-posta saklanmaz (herkese açık tablo); sadece görünen ad.
              'user_name': displayNameFor(user),
            },
            onConflict: 'place_id,user_id',
          )
          .select()
          .single();

      return Review.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  /// Herkese açık tablolarda gösterilecek ad: profildeki ad, yoksa
  /// e-postanın @ öncesi. Tam e-posta adresi asla yazılmaz.
  static String displayNameFor(User user) {
    final meta = user.userMetadata ?? const {};
    final name = (meta['full_name'] ?? meta['name'] ?? '').toString().trim();
    if (name.isNotEmpty) return name;
    final email = user.email ?? '';
    return email.contains('@') ? email.split('@').first : 'Gezgin';
  }

  /// Kullanıcının kendi yorumunu siler
  static Future<bool> delete(String placeId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;
    try {
      await _supabase
          .from('reviews')
          .delete()
          .eq('place_id', placeId)
          .eq('user_id', user.id);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Mekanın ortalama puanı ve yorum sayısı
  static Future<RatingSummary> getRatingSummary(String placeId) async {
    try {
      final response =
          await _supabase.from('reviews').select('rating').eq('place_id', placeId);
      final list = (response as List);
      if (list.isEmpty) return const RatingSummary(average: 0, count: 0);
      final total = list.fold<int>(0, (s, r) => s + (r['rating'] as int? ?? 0));
      return RatingSummary(
        average: total / list.length,
        count: list.length,
      );
    } catch (_) {
      return const RatingSummary(average: 0, count: 0);
    }
  }
}

class Review {
  final String id;
  final String placeId;
  final String userId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String? userName;
  final List<String> photos;

  Review({
    required this.id,
    required this.placeId,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.userName,
    this.photos = const [],
  });

  String get displayName {
    if (userName == null || userName!.trim().isEmpty) return 'Gezgin';
    return userName!.trim();
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      placeId: json['place_id'] as String,
      userId: json['user_id'] as String,
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      userName: json['user_name'] as String?,
      photos: (json['photos'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }
}

class RatingSummary {
  final double average;
  final int count;
  const RatingSummary({required this.average, required this.count});
}
