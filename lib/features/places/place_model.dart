/// Mekan modeli — Supabase places tablosundan gelir.
/// Eski kayıtlarda olmayan kolonlar için tüm yeni alanlar opsiyoneldir.
class Place {
  final String id;
  final String cityId;
  final String name;
  final String nameEn;
  final String description;
  final String descriptionEn;
  final String category;
  final String emoji;
  final double? latitude;
  final double? longitude;
  final bool isFree;
  final bool isFeatured;
  final double rating;

  // ─── Yeni opsiyonel alanlar ──────────────────────────────────
  /// Adres (örn. "Sultanahmet Mh., Fatih/İstanbul")
  final String? address;

  /// Giriş ücreti açıklaması (örn. "50 TL", "100 TL / öğrenci 50 TL")
  final String? admissionFee;

  /// Açılış saatleri — JSON formatında ya da düz metin
  /// Örn: "Pazartesi kapalı, Sal-Paz 09:00-17:00"
  final String? openingHours;

  /// Web sitesi URL'i
  final String? website;

  /// Telefon numarası (E.164 formatında ideal: "+90 212 ...")
  final String? phone;

  /// Foto galerisi — birden fazla görsel URL'i.
  /// Boşsa veya null'sa emoji + gradient fallback gösterilir.
  final List<String> images;

  /// Detaylı tarihçe metni (Wikipedia'dan toplu doldurma ile yazılır).
  final String? history;

  Place({
    required this.id,
    required this.cityId,
    required this.name,
    required this.nameEn,
    required this.description,
    required this.descriptionEn,
    required this.category,
    required this.emoji,
    this.latitude,
    this.longitude,
    required this.isFree,
    required this.isFeatured,
    required this.rating,
    this.address,
    this.admissionFee,
    this.openingHours,
    this.website,
    this.phone,
    this.images = const [],
    this.history,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as String,
      cityId: json['city_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      description: json['description'] as String? ?? '',
      descriptionEn: json['description_en'] as String? ?? '',
      category: json['category'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '📍',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isFree: json['is_free'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String?,
      admissionFee: json['admission_fee'] as String?,
      openingHours: json['opening_hours'] as String?,
      website: json['website'] as String?,
      phone: json['phone'] as String?,
      images: _parseImages(json['images']),
      history: json['history'] as String?,
    );
  }

  /// images Supabase'de JSONB array veya text[] olabilir.
  /// İkisini de güvenle parse eder.
  static List<String> _parseImages(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    if (raw is String && raw.isNotEmpty) {
      // Tek URL string olarak da kabul et
      return [raw];
    }
    return const [];
  }
}
