import 'package:supabase_flutter/supabase_flutter.dart';

import 'diary_models.dart';

/// Gezi günlüğü Supabase servisi.
/// Tablolar: trip_diaries, diary_entries (README'de SQL var)
class DiaryService {
  static final _supabase = Supabase.instance.client;

  /// Kullanıcının tüm defterleri (yeni→eski).
  static Future<List<TripDiary>> getMyDiaries() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return const [];
    try {
      final response = await _supabase
          .from('trip_diaries')
          .select('*, diary_entries(count)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return (response as List).map((row) {
        final r = row as Map<String, dynamic>;
        final counts = r['diary_entries'] as List?;
        final count = (counts != null && counts.isNotEmpty)
            ? ((counts.first as Map)['count'] as num).toInt()
            : 0;
        return TripDiary.fromJson({...r, 'entry_count': count});
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Tek bir defteri (kendi veya public)
  static Future<TripDiary?> getDiary(String id) async {
    try {
      final response = await _supabase
          .from('trip_diaries')
          .select('*, diary_entries(count)')
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      final counts = response['diary_entries'] as List?;
      final count = (counts != null && counts.isNotEmpty)
          ? ((counts.first as Map)['count'] as num).toInt()
          : 0;
      return TripDiary.fromJson({...response, 'entry_count': count});
    } catch (_) {
      return null;
    }
  }

  /// Bir defterin girdileri (tarih sırası ile)
  static Future<List<DiaryEntry>> getEntries(String diaryId) async {
    try {
      final response = await _supabase
          .from('diary_entries')
          .select('*, places(name, emoji)')
          .eq('diary_id', diaryId)
          .order('entry_date', ascending: false);
      return (response as List)
          .map((r) => DiaryEntry.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Yeni defter oluştur
  static Future<TripDiary?> createDiary({
    required String title,
    required String emoji,
    String? coverColor,
    DateTime? startDate,
    DateTime? endDate,
    bool isPublic = false,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    try {
      final response = await _supabase.from('trip_diaries').insert({
        'user_id': user.id,
        'title': title,
        'emoji': emoji,
        if (coverColor != null) 'cover_color': coverColor,
        if (startDate != null)
          'start_date': startDate.toIso8601String().split('T').first,
        if (endDate != null)
          'end_date': endDate.toIso8601String().split('T').first,
        'is_public': isPublic,
      }).select().single();
      return TripDiary.fromJson({...response, 'entry_count': 0});
    } catch (_) {
      return null;
    }
  }

  /// Defter sil
  static Future<bool> deleteDiary(String id) async {
    try {
      await _supabase.from('trip_diaries').delete().eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Yeni girdi ekle
  static Future<DiaryEntry?> addEntry({
    required String diaryId,
    String? placeId,
    required DateTime entryDate,
    required String note,
    String? photoUrl,
    String? mood,
  }) async {
    try {
      final response = await _supabase.from('diary_entries').insert({
        'diary_id': diaryId,
        if (placeId != null) 'place_id': placeId,
        'entry_date': entryDate.toIso8601String().split('T').first,
        'note': note,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (mood != null) 'mood': mood,
      }).select('*, places(name, emoji)').single();
      return DiaryEntry.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  /// Girdi sil
  static Future<bool> deleteEntry(String id) async {
    try {
      await _supabase.from('diary_entries').delete().eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }
}
