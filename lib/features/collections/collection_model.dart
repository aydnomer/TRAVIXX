/// Tematik mekan koleksiyonu (UNESCO, sahil tatili, romantik şehirler vb.)
class PlaceCollection {
  final String id;
  final String name;
  final String nameEn;
  final String emoji;
  final String description;
  final String? descriptionEn;
  final String coverGradientStart; // hex (#RRGGBB)
  final String coverGradientEnd;
  final int placeCount;
  final int displayOrder;

  const PlaceCollection({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.emoji,
    required this.description,
    this.descriptionEn,
    required this.coverGradientStart,
    required this.coverGradientEnd,
    required this.placeCount,
    required this.displayOrder,
  });

  factory PlaceCollection.fromJson(Map<String, dynamic> json) {
    return PlaceCollection(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '✨',
      description: json['description'] as String? ?? '',
      descriptionEn: json['description_en'] as String?,
      coverGradientStart: json['gradient_start'] as String? ?? '#1A2744',
      coverGradientEnd: json['gradient_end'] as String? ?? '#F97316',
      placeCount: (json['place_count'] as num?)?.toInt() ?? 0,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
    );
  }
}
