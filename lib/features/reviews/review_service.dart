import 'package:supabase_flutter/supabase_flutter.dart';

/// Mekan yorumları servisi.
///
/// Supabase tablosu (README'de SQL'i var):
///   reviews(id, place_id, user_id, rating, comment, created_at, user_email)
///   UNIQUE(place_id, user_id) — bir kullanıcı bir mekana bir yorum
///
/// RLS:
///   - Herkes okuyabilir (yorumlar public)
///   - Sadece sahibi insert/update/delete edebilir
class ReviewService {
  static final _supabase = Supabase.instance.client;

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
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    if (rating < 1 || rating > 5) return null;

    try {
      final response = await _supabase
          .from('reviews')
          .upsert({
            'place_id': placeId,
            'user_id': user.id,
            'rating': rating,
            'comment': comment.trim(),
            'user_email': user.email,
          })
          .select()
          .single();

      return Review.fromJson(response);
    } catch (_) {
      return null;
    }
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
  final String? userEmail;

  Review({
    required this.id,
    required this.placeId,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.userEmail,
  });

  /// Kullanıcı adı için e-posta'nın @ öncesi (gizlilik için)
  String get displayName {
    if (userEmail == null || userEmail!.isEmpty) return 'Gezgin';
    return userEmail!.split('@').first;
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
      userEmail: json['user_email'] as String?,
    );
  }
}

class RatingSummary {
  final double average;
  final int count;
  const RatingSummary({required this.average, required this.count});
}
