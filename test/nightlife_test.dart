import 'package:flutter_test/flutter_test.dart';
import 'package:travixx/core/constants/categories.dart';
import 'package:travixx/core/utils/price_service.dart';
import 'package:travixx/features/places/place_model.dart';

import '../tool/osm/osm_mapper.dart';

void main() {
  group('classify: gece hayatı', () {
    test('beach club etiketleri ve adı', () {
      expect(classify({'leisure': 'beach_resort'})!.subcategory, 'Beach Club');
      expect(classify({'amenity': 'bar', 'name': 'Xuma Beach'})!.subcategory,
          'Beach Club');
      expect(classify({'amenity': 'nightclub', 'name': 'Halikarnas'})!.subcategory,
          'Gece Kulübü');
      expect(classify({'amenity': 'bar', 'name': 'Moonlight'})!.subcategory, 'Bar');
      expect(classify({'amenity': 'pub', 'name': 'The Red Lion'})!.subcategory, 'Pub');
      expect(classify({'amenity': 'bar', 'name': 'Moonlight'})!.category,
          Categories.nightlife);
      // "Beachside" gibi kelime içi eşleşme beach club sayılmaz
      expect(classify({'amenity': 'bar', 'name': 'Beachside'})!.subcategory, 'Bar');
      // Doğal plaj hâlâ Plaj
      expect(classify({'natural': 'beach', 'name': 'Ilıca Beach'})!.category, 'Plaj');
    });

    test('toPlaceRow gece hayatı alanlarını taşır', () {
      final row = toPlaceRow({
        'type': 'node',
        'id': 7,
        'lat': 37.03,
        'lon': 27.43,
        'tags': {
          'amenity': 'nightclub',
          'name': 'Club Test',
          'contact:instagram': '@clubtest',
          'reservation:url': 'https://example.com/book',
          'min_age': '18',
          'music': 'house;techno',
        },
      }, 'c')!;
      expect(row['instagram'], 'https://instagram.com/clubtest');
      expect(row['reservation_url'], 'https://example.com/book');
      expect(row['min_age'], 18);
      expect(row['music'], 'house;techno');
    });
  });

  group('instagramUrl', () {
    test('kullanıcı adı ve https kabul edilir', () {
      expect(instagramUrl('xuma.beach'), 'https://instagram.com/xuma.beach');
      expect(instagramUrl('@xuma'), 'https://instagram.com/xuma');
      expect(instagramUrl('https://www.instagram.com/xuma/'),
          'https://www.instagram.com/xuma/');
    });
    test('geçersiz değerler atlanır', () {
      expect(instagramUrl(null), isNull);
      expect(instagramUrl(''), isNull);
      expect(instagramUrl('javascript:alert(1)'), isNull);
      expect(instagramUrl('http://insecure.example'), isNull);
      expect(instagramUrl('has space'), isNull);
    });
  });

  group('PriceService', () {
    test('format', () {
      expect(PriceService.format(750, 'TRY'), '₺750');
      expect(PriceService.format(12.5, 'EUR'), '€12.50');
      expect(PriceService.format(10, 'GBP'), '£10');
    });
    test('PriceSummary.fromJson', () {
      final s = PriceSummary.fromJson({
        'place_id': 'p',
        'item': 'sunbed',
        'currency': 'TRY',
        'median': 1500,
        'low': '1000',
        'high': 2000.0,
        'reports': 3,
        'last_seen': '2026-10-30',
      });
      expect(s.median, 1500);
      expect(s.high, 2000);
      expect(s.reports, 3);
      expect(s.lastSeen, DateTime(2026, 10, 30));
    });
  });

  test('Place gece hayatı alanları', () {
    final p = Place.fromJson({
      'id': 'x',
      'category': 'Eğlence',
      'subcategory': 'Beach Club',
      'instagram': 'https://instagram.com/x',
      'min_age': 18,
      'music': 'house',
    });
    expect(p.isNightlife, isTrue);
    expect(p.minAge, 18);
    expect(p.instagram, 'https://instagram.com/x');
  });
}
