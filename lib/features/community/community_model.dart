class CommunityPost {
  final String id;
  final String userId;
  final String userEmail;
  final String title;
  final String description;
  final String? cityName;
  final String? imageUrl;
  final DateTime createdAt;

  CommunityPost({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.title,
    required this.description,
    this.cityName,
    this.imageUrl,
    required this.createdAt,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      userEmail: json['user_email'] as String? ?? 'Gezgin',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      cityName: json['city_name'] as String?,
      imageUrl: json['image_url'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
              DateTime.now(),
    );
  }
}
