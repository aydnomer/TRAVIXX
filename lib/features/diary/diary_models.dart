/// Kullanıcının gezi defterleri ve içlerindeki günlük girdiler.
class TripDiary {
  final String id;
  final String userId;
  final String title;
  final String emoji;
  final String? coverColor; // hex
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isPublic;
  final int entryCount;
  final DateTime createdAt;

  const TripDiary({
    required this.id,
    required this.userId,
    required this.title,
    required this.emoji,
    this.coverColor,
    this.startDate,
    this.endDate,
    required this.isPublic,
    required this.entryCount,
    required this.createdAt,
  });

  factory TripDiary.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      return null;
    }

    return TripDiary(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '📖',
      coverColor: json['cover_color'] as String?,
      startDate: parseDate(json['start_date']),
      endDate: parseDate(json['end_date']),
      isPublic: json['is_public'] as bool? ?? false,
      entryCount: (json['entry_count'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(json['created_at']) ?? DateTime.now(),
    );
  }
}

class DiaryEntry {
  final String id;
  final String diaryId;
  final String? placeId;
  final String? placeName;
  final String? placeEmoji;
  final DateTime entryDate;
  final String note;
  final String? photoUrl;
  final String? mood;
  final DateTime createdAt;

  const DiaryEntry({
    required this.id,
    required this.diaryId,
    this.placeId,
    this.placeName,
    this.placeEmoji,
    required this.entryDate,
    required this.note,
    this.photoUrl,
    this.mood,
    required this.createdAt,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    // places nested object (join sonucu) — varsa adı ve emojisini al
    final placesJoin = json['places'];
    String? pName;
    String? pEmoji;
    if (placesJoin is Map) {
      pName = placesJoin['name'] as String?;
      pEmoji = placesJoin['emoji'] as String?;
    }

    return DiaryEntry(
      id: json['id'] as String,
      diaryId: json['diary_id'] as String,
      placeId: json['place_id'] as String?,
      placeName: pName,
      placeEmoji: pEmoji,
      entryDate: DateTime.tryParse(json['entry_date'] as String? ?? '') ??
          DateTime.now(),
      note: json['note'] as String? ?? '',
      photoUrl: json['photo_url'] as String?,
      mood: json['mood'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
