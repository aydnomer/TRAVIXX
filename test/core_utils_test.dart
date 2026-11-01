import 'package:flutter_test/flutter_test.dart';
import 'package:travixx/core/constants/categories.dart';
import 'package:travixx/core/i18n/i18n.dart';
import 'package:travixx/core/utils/gps_service.dart';
import 'package:travixx/core/utils/qr_service.dart';
import 'package:travixx/features/places/place_model.dart';

void main() {
  group('Categories', () {
    test('karaktersiz DB yazımını doğru ada çevirir', () {
      expect(Categories.normalize('Doga'), 'Doğa');
      expect(Categories.normalize('Muze'), 'Müze');
      expect(Categories.normalize('Kultur'), 'Kültür');
      expect(Categories.normalize('Alisveris'), 'Alışveriş');
      expect(Categories.normalize('Tarihi'), 'Tarihi');
      expect(Categories.normalize('Bilinmeyen'), 'Bilinmeyen');
    });

    test('fold Türkçe büyük harfleri doğru indirger', () {
      expect(Categories.fold('İstanbul'), 'istanbul');
      expect(Categories.fold('IĞDIR'), 'igdir');
      expect(Categories.fold('Müzesi'), 'muzesi');
    });

    test('containsAny karaktersiz metinde Türkçe anahtar kelimeyi bulur', () {
      expect(Categories.containsAny('Rumeli Hisari', ['hisar']), isTrue);
      expect(Categories.containsAny('Selimiye Camii', ['cami']), isTrue);
      expect(Categories.containsAny('Elazig Muzesi', ['müze']), isTrue);
      expect(Categories.containsAny('Uzungol', ['müze']), isFalse);
    });

    test('Place.fromJson kategoriyi normalize eder', () {
      final p = Place.fromJson({'id': '1', 'name': 'Uzungol', 'category': 'Doga'});
      expect(p.category, Categories.nature);
    });
  });

  group('QrService.extractCode', () {
    const id = '0b3f6c1e-8a1d-4b2e-9f00-123456789abc';
    test('web linkinden kodu ayıklar', () {
      expect(QrService.extractCode(QrService.linkForPlace(id)), id);
      expect(QrService.extractCode('https://x.y/TRAVIXX/#/place/$id'), id);
    });
    test('düz metni olduğu gibi döner', () {
      expect(QrService.extractCode('  TRVX-001 '), 'TRVX-001');
    });
  });

  test('GpsService.distanceKm ~1 km kuzey için ~1 km verir', () {
    // 0.009° enlem ≈ 1 km
    final km = GpsService.distanceKm(41.0, 29.0, 41.009, 29.0);
    expect(km, closeTo(1.0, 0.01));
  });

  test('her dilde TR ile aynı i18n anahtarları var mı (yeni eklenenler)', () {
    for (final lang in ['tr', 'en', 'de', 'ar', 'fr', 'ru']) {
      I18n.language.value = lang;
      for (final key in [
        'qrPrint.title',
        'qrPrint.hint',
        'region.thrace',
        'region.westernBlackSea',
        'place.category',
      ]) {
        expect(I18n.t(key), isNot(key), reason: '$lang: $key eksik');
      }
    }
    I18n.language.value = 'tr';
  });
}
