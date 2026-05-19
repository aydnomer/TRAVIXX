class City {
  final String id;
  final String name;
  final String nameEn;
  final String region;
  final String emoji;
  final String? imageUrl;
  final int placeCount;
  final double? latitude;
  final double? longitude;

  City({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.region,
    required this.emoji,
    this.imageUrl,
    required this.placeCount,
    this.latitude,
    this.longitude,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      region: json['region'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      placeCount: json['place_count'] as int? ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
