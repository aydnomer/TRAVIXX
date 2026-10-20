import 'package:flutter_test/flutter_test.dart';
import 'package:travixx/core/utils/translation_service.dart';

import '../tool/wiki/wiki_match.dart';

void main() {
  group('fixedName', () {
    test('karaktersiz ad Wikipedia başlığıyla düzelir', () {
      expect(fixedName('Ataturk Kosku', 'Atatürk Köşkü (Trabzon)'),
          'Atatürk Köşkü');
      expect(fixedName('Sumela Manastiri', 'Sümela Manastırı'),
          'Sümela Manastırı');
    });

    test('farklı kelimeler ya da zaten doğru ad değişmez', () {
      expect(fixedName('Eski Gumusler', 'Eski Gümüş Manastırı'), isNull);
      expect(fixedName('Atatürk Köşkü', 'Atatürk Köşkü'), isNull);
    });
  });

  group('isSamePlace', () {
    test('yakın ve ortak kelime → aynı yer', () {
      expect(
          isSamePlace(
              name: 'Sumela Manastiri',
              lat: 40.690,
              lng: 39.658,
              title: 'Sümela Manastırı',
              wikiLat: 40.6903,
              wikiLng: 39.6581),
          isTrue);
    });

    test('uzaktaki aynı adlı makale reddedilir', () {
      expect(
          isSamePlace(
              name: 'Ulu Cami',
              lat: 40.18,
              lng: 29.06,
              title: 'Ulu Cami (Erzurum)',
              wikiLat: 39.90,
              wikiLng: 41.27),
          isFalse);
    });

    test('koordinat yoksa ad birebir aynı olmalı', () {
      expect(isSamePlace(name: 'Efes', title: 'Efes'), isTrue);
      expect(isSamePlace(name: 'Efes', title: 'Efes Müzesi'), isFalse);
    });
  });

  test('clip cümle sonunda keser', () {
    final text = '${'Bir cümle. ' * 50}Son';
    final out = clip(text, 100)!;
    expect(out.length, lessThanOrEqualTo(100));
    expect(out.endsWith('.'), isTrue);
    expect(clip('   ', 10), isNull);
  });

  test('shortDescription ilk paragrafı alır', () {
    expect(shortDescription('İlk paragraf.\n\nİkinci paragraf.'),
        'İlk paragraf.');
  });

  test('parseWikiTag', () {
    expect(parseWikiTag('tr:Efes')?.title, 'Efes');
    expect(parseWikiTag('Efes'), isNull);
  });

  test('PlaceText boş alanları null sayar', () {
    final t = PlaceText.fromJson(
        {'lang': 'de', 'name': 'Ephesos', 'description': '  ', 'history': null});
    expect(t.name, 'Ephesos');
    expect(t.description, isNull);
  });
}
