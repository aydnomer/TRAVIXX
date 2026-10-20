import 'package:flutter_test/flutter_test.dart';
import 'package:travixx/features/places/place_model.dart';
import 'package:travixx/features/reviews/review_service.dart';

void main() {
  test('yorum fotoğrafları okunur, eski kayıtta boş liste', () {
    final r = Review.fromJson({
      'id': '1',
      'place_id': 'p',
      'user_id': 'u',
      'rating': 4,
      'photos': ['https://x.supabase.co/a.jpg'],
    });
    expect(r.photos, hasLength(1));
    expect(
        Review.fromJson({'id': '2', 'place_id': 'p', 'user_id': 'u'}).photos,
        isEmpty);
  });

  test('yorum varsa kullanıcı ortalaması, yoksa tahmini puan gösterilir', () {
    final seeded = Place.fromJson({'id': 'a', 'rating': 4.8});
    expect(seeded.ratingLabel, '4.8');

    final reviewed = Place.fromJson({
      'id': 'b',
      'rating': 4.8,
      'review_count': 3,
      'review_avg': 3.7,
    });
    expect(reviewed.displayRating, 3.7);
    expect(reviewed.ratingLabel, '3.7');

    final osmNew = Place.fromJson({'id': 'c', 'rating': 0, 'review_count': 0});
    expect(osmNew.ratingLabel, '—');
  });
}
