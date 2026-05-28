import 'package:supabase_flutter/supabase_flutter.dart';
import 'community_model.dart';

class CommunityService {
  static final _db = Supabase.instance.client;

  static Future<List<CommunityPost>> getPosts() async {
    try {
      final res = await _db
          .from('community_posts')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      return (res as List).map((e) => CommunityPost.fromJson(e)).toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<bool> addPost({
    required String title,
    required String description,
    String? cityName,
    String? imageUrl,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) return false;
    try {
      await _db.from('community_posts').insert({
        'user_id': user.id,
        'user_email': user.email,
        'title': title,
        'description': description,
        if (cityName != null && cityName.isNotEmpty) 'city_name': cityName,
        if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deletePost(String id) async {
    try {
      await _db.from('community_posts').delete().eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }
}
