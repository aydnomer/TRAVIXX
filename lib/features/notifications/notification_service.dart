import 'package:supabase_flutter/supabase_flutter.dart';

/// In-app bildirim servisi.
/// Supabase tablosu: notifications (user_id, type, title, body, link, is_read, created_at)
/// Realtime stream ile yeni bildirimler anlık gelir.
class NotificationService {
  static final _supabase = Supabase.instance.client;

  /// Kullanıcının bildirimleri (yeni→eski, limit 50)
  static Future<List<AppNotification>> getNotifications() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return const [];
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(50);
      return (response as List)
          .map((r) => AppNotification.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Okunmamış bildirim sayısı
  static Future<int> getUnreadCount() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 0;
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .eq('is_read', false);
      return (response as List).length;
    } catch (_) {
      return 0;
    }
  }

  /// Bir bildirimi okundu olarak işaretle
  static Future<void> markAsRead(String id) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true}).eq('id', id);
    } catch (_) {}
  }

  /// Tüm bildirimleri okundu işaretle
  static Future<void> markAllAsRead() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);
    } catch (_) {}
  }

  /// Realtime stream — yeni bildirim geldiğinde tetiklenir
  static Stream<List<Map<String, dynamic>>> watchNotifications() {
    final user = _supabase.auth.currentUser;
    if (user == null) return const Stream.empty();
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(50);
  }
}

class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final String? link;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.link,
    required this.isRead,
    required this.createdAt,
  });

  String get emoji {
    switch (type) {
      case 'badge_earned':
        return '🏆';
      case 'new_review':
        return '⭐';
      case 'nearby_place':
        return '📍';
      case 'welcome':
        return '👋';
      default:
        return '🔔';
    }
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String? ?? 'general',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      link: json['link'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
