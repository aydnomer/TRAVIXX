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
    );
  }
}
