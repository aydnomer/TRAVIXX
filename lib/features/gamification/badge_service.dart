import 'package:supabase_flutter/supabase_flutter.dart';

/// Rozet ve ziyaret takip sistemi.
///
/// Supabase tablosu (kullanıcı oluşturmalı, README'de var):
///   visits(id, user_id, place_id, visited_at)
///
/// Çalışma:
/// - Kullanıcı bir mekan detayı açtığında recordVisit() çağrılır
/// - Aynı mekanı 24 saat içinde tekrar açarsa yeni kayıt oluşmaz (deduplikasyon)
/// - getStats() ziyaret sayısı + kategori bazlı kırılım döner
/// - getEarnedBadges() statlara göre kazanılan rozetleri verir
class BadgeService {
  static final _supabase = Supabase.instance.client;

  /// Mekan ziyaretini kaydet (kullanıcı giriş yapmamışsa atlanır)
  static Future<void> recordVisit(String placeId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Son 24 saat içinde aynı yer için kayıt var mı?
      final since = DateTime.now()
          .subtract(const Duration(hours: 24))
          .toIso8601String();
      final existing = await _supabase
          .from('visits')
          .select('id')
          .eq('user_id', user.id)
          .eq('place_id', placeId)
          .gte('visited_at', since)
          .limit(1)
          .maybeSingle();

      if (existing != null) return; // 24 saat içinde zaten ziyaret edildi

      await _supabase.from('visits').insert({
        'user_id': user.id,
        'place_id': placeId,
      });
    } catch (_) {
      // Sessiz hata — gamification kritik değil, app'i kırma
    }
  }

  /// Kullanıcının ziyaret istatistikleri
  static Future<UserStats> getStats() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return UserStats.empty();

    try {
      // Tüm ziyaretleri çek + place'ın kategorisi
      final response = await _supabase
          .from('visits')
          .select('place_id, places(category)')
          .eq('user_id', user.id);

      final visits = (response as List);
      final total = visits.length;
      final uniquePlaces = visits.map((v) => v['place_id']).toSet().length;

      // Kategori bazlı dağılım
      final byCategory = <String, int>{};
      for (final v in visits) {
        final places = v['places'];
        if (places is Map && places['category'] != null) {
          final cat = places['category'] as String;
          byCategory[cat] = (byCategory[cat] ?? 0) + 1;
        }
      }

      return UserStats(
        totalVisits: total,
        uniquePlaces: uniquePlaces,
        byCategory: byCategory,
      );
    } catch (_) {
      return UserStats.empty();
    }
  }

  /// Kullanıcının statlarına göre kazanılan rozetleri döner
  static List<BadgeInfo> getEarnedBadges(UserStats stats) {
    final earned = <BadgeInfo>[];
    for (final b in allBadges) {
      if (b.isEarned(stats)) earned.add(b);
    }
    return earned;
  }

  /// Tüm tanımlı rozetler (kazanılmış ve kazanılmamış)
  static List<BadgeInfo> get allBadges => const [
        BadgeInfo(
          id: 'first_step',
          emoji: '👣',
          titleKey: 'badge.firstStep.title',
          descKey: 'badge.firstStep.desc',
          tier: BadgeTier.bronze,
          requiredUniquePlaces: 1,
        ),
        BadgeInfo(
          id: 'explorer',
          emoji: '🗺️',
          titleKey: 'badge.explorer.title',
          descKey: 'badge.explorer.desc',
          tier: BadgeTier.bronze,
          requiredUniquePlaces: 5,
        ),
        BadgeInfo(
          id: 'museum_lover',
          emoji: '🖼️',
          titleKey: 'badge.museumLover.title',
          descKey: 'badge.museumLover.desc',
          tier: BadgeTier.silver,
          requiredCategoryCount: 5,
          requiredCategory: 'Müze',
        ),
        BadgeInfo(
          id: 'history_buff',
          emoji: '🏛️',
          titleKey: 'badge.historyBuff.title',
          descKey: 'badge.historyBuff.desc',
          tier: BadgeTier.silver,
          requiredCategoryCount: 5,
          requiredCategory: 'Tarihi',
        ),
        BadgeInfo(
          id: 'nature_lover',
          emoji: '🌿',
          titleKey: 'badge.natureLover.title',
          descKey: 'badge.natureLover.desc',
          tier: BadgeTier.silver,
          requiredCategoryCount: 5,
          requiredCategory: 'Doğa',
        ),
        BadgeInfo(
          id: 'adventurer',
          emoji: '🎒',
          titleKey: 'badge.adventurer.title',
          descKey: 'badge.adventurer.desc',
          tier: BadgeTier.gold,
          requiredUniquePlaces: 20,
        ),
        BadgeInfo(
          id: 'master_traveler',
          emoji: '✈️',
          titleKey: 'badge.masterTraveler.title',
          descKey: 'badge.masterTraveler.desc',
          tier: BadgeTier.gold,
          requiredUniquePlaces: 50,
        ),
      ];
}

enum BadgeTier { bronze, silver, gold }

class BadgeInfo {
  final String id;
  final String emoji;
  final String titleKey;
  final String descKey;
  final BadgeTier tier;
  final int? requiredUniquePlaces;
  final int? requiredCategoryCount;
  final String? requiredCategory;

  const BadgeInfo({
    required this.id,
    required this.emoji,
    required this.titleKey,
    required this.descKey,
    required this.tier,
    this.requiredUniquePlaces,
    this.requiredCategoryCount,
    this.requiredCategory,
  });

  bool isEarned(UserStats stats) {
    if (requiredUniquePlaces != null) {
      if (stats.uniquePlaces < requiredUniquePlaces!) return false;
    }
    if (requiredCategoryCount != null && requiredCategory != null) {
      final count = stats.byCategory[requiredCategory!] ?? 0;
      if (count < requiredCategoryCount!) return false;
    }
    return true;
  }
}

class UserStats {
  final int totalVisits;
  final int uniquePlaces;
  final Map<String, int> byCategory;

  const UserStats({
    required this.totalVisits,
    required this.uniquePlaces,
    required this.byCategory,
  });

  factory UserStats.empty() => const UserStats(
        totalVisits: 0,
        uniquePlaces: 0,
        byCategory: {},
      );
}
