import 'package:flutter_test/flutter_test.dart';
import 'package:travixx/core/constants/categories.dart';
import 'package:travixx/features/places/place_model.dart';

import '../tool/osm/osm_mapper.dart';

void main() {
  group('classify', () {
    test('plaj, müze, antik kent, şelale, cami', () {
      expect(classify({'natural': 'beach'})!.category, 'Plaj');
      expect(classify({'tourism': 'museum'})!.category, 'Müze');
      expect(classify({'historic': 'archaeological_site'})!.subcategory,
          'Antik Kent / Ören Yeri');
      expect(classify({'waterway': 'waterfall'})!.subcategory, 'Şelale');
      expect(classify({'amenity': 'place_of_worship', 'religion': 'muslim'})!
          .subcategory, 'Cami');
    });

    test('tanınmayan etiket atlanır', () {
      expect(classify({'amenity': 'parking'}), isNull);
      expect(classify({'boundary': 'protected_area', 'protect_class': '5'}),
          isNull);
    });

    test('aktarımın tüm kategorileri uygulamada tanınıyor', () {
      for (final tags in [
        {'natural': 'beach'},
        {'tourism': 'museum'},
        {'historic': 'castle'},
        {'amenity': 'place_of_worship'},
        {'natural': 'cave_entrance'},
        {'tourism': 'viewpoint'},
        {'tourism': 'attraction'},
      ]) {
        final c = classify(tags)!.category;
        expect(Categories.all, contains(Categories.normalize(c)), reason: c);
      }
    });
  });

  group('toPlaceRow', () {
    test('way için merkez koordinatı ve etiketler', () {
      final row = toPlaceRow({
        'type': 'way',
        'id': 42,
        'center': {'lat': 36.5, 'lon': 30.5},
        'tags': {
          'natural': 'beach',
          'name': 'Kaputaş Beach',
          'name:tr': 'Kaputaş Plajı',
          'fee': 'no',
          'wikipedia': 'tr:Kaputaş Plajı',
        },
      }, 'city-1')!;
      expect(row['osm_ref'], 'way/42');
      expect(row['source'], 'osm');
      expect(row['name'], 'Kaputaş Plajı');
      expect(row['latitude'], 36.5);
      expect(row['is_free'], isTrue);
      expect(row['wikipedia'], 'tr:Kaputaş Plajı');
      expect(row.containsKey('rating'), isFalse,
          reason: 'yeniden aktarım puanı ezmemeli');
    });

    test('adsız ya da koordinatsız öğe atlanır', () {
      expect(
          toPlaceRow({'type': 'node', 'id': 1, 'lat': 1, 'lon': 1,
              'tags': {'natural': 'beach'}}, 'c'),
          isNull);
      expect(
          toPlaceRow({'type': 'way', 'id': 1,
              'tags': {'natural': 'beach', 'name': 'X Plajı'}}, 'c'),
          isNull);
    });
  });

  group('isDuplicateOf', () {
    final curated = {
      'name': 'Efes Antik Kenti',
      'name_en': 'Ephesus',
      'latitude': 37.9394,
      'longitude': 27.3417,
    };

    test('yakın ve ortak adlı kayıt aynı yer sayılır', () {
      final row = {
        'name': 'Efes Ören Yeri',
        'name_en': '',
        'latitude': 37.9410,
        'longitude': 27.3420,
      };
      expect(isDuplicateOf(row, [curated]), isTrue);
    });

    test('uzak ya da farklı adlı kayıt ayrı yer', () {
      expect(
          isDuplicateOf({
            'name': 'Efes Ören Yeri',
            'name_en': '',
            'latitude': 38.5,
            'longitude': 27.3,
          }, [curated]),
          isFalse);
      expect(
          isDuplicateOf({
            'name': 'Meryem Ana Evi',
            'name_en': '',
            'latitude': 37.9400,
            'longitude': 27.3418,
          }, [curated]),
          isFalse);
    });
  });

  test('81 il ve Overpass sorgusu plaka kodunu kullanır', () {
    expect(provinces.length, 81);
    expect(overpassQuery('07'), contains('TR-07'));
  });

  group('Place', () {
    test('OSM alanları ve puan etiketi', () {
      final p = Place.fromJson({
        'id': 'x',
        'source': 'osm',
        'subcategory': 'Şelale',
        'rating': 0,
        'wikipedia': 'tr:Düden Şelalesi',
      });
      expect(p.isFromOsm, isTrue);
      expect(p.subcategory, 'Şelale');
      expect(p.ratingLabel, '—');
      expect(Place.fromJson({'id': 'y', 'rating': 4.56}).ratingLabel, '4.6');
      expect(Place.fromJson({'id': 'z'}).source, 'travixx');
    });
  });
}
