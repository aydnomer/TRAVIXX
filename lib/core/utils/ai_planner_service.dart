import 'database_service.dart';
import '../../features/cities/city_model.dart';
import '../../features/places/place_model.dart';

/// Akıllı gezi planlayıcı.
///
/// Kullanıcı doğal dil ile sorgu yazar:
///   "İstanbul'da 2 gün"
///   "Antalya hafta sonu"
///   "Kapadokya 3 günlük rota"
///
/// Bu servis:
/// 1. Sorguyu parse eder (şehir + gün sayısı)
/// 2. Supabase'den o şehrin en yüksek puanlı mekanlarını çeker
/// 3. Günlük 4 mekanlık rotalar üretir (sabah-öğle-öğleden sonra-akşam)
/// 4. Kategori çeşitliliği gözetir (sadece müze, sadece doğa değil)
///
/// Avantaj: LLM API'sine ihtiyaç yok, hızlı, ücretsiz, deterministik.
class AiPlannerService {
  static List<City>? _citiesCache;

  /// Sorgu metnini parse edip plan üretir.
  /// Geçersiz/anlaşılmaz sorgu için null döner.
  static Future<TripPlan?> plan(String query) async {
    final cities = await _getCities();
    if (cities.isEmpty) return null;

    final lower = query.toLowerCase().trim();
    if (lower.isEmpty) return null;

    // 1) Şehir tespit
    City? matchedCity;
    for (final c in cities) {
      final n = c.name.toLowerCase();
      final en = c.nameEn.toLowerCase();
      if (lower.contains(n) ||
          (en.isNotEmpty && lower.contains(en))) {
        matchedCity = c;
        break;
      }
    }
    if (matchedCity == null) return null;

    // 2) Gün sayısı tespit
    int days = _parseDays(lower);

    // 3) Mekanları çek (rating'e göre sıralı)
    final places = await DatabaseService.getPlacesByCity(matchedCity.id);
    if (places.isEmpty) {
      return TripPlan(
        city: matchedCity,
        days: days,
        itinerary: const [],
        summary: '',
      );
    }

    // 4) Kategori çeşitliliği — günlük 4 farklı kategori öncelikli
    final perDay = 4;
    final totalNeeded = days * perDay;

    // Kategorilere göre grupla
    final byCategory = <String, List<Place>>{};
    for (final p in places) {
      byCategory.putIfAbsent(p.category, () => []).add(p);
    }

    // Round-robin: kategorilerden sırayla seç ki çeşitlilik olsun
    final picked = <Place>[];
    final usedIds = <String>{};
    int attempts = 0;
    while (picked.length < totalNeeded && attempts < places.length * 2) {
      attempts++;
      for (final cat in byCategory.keys) {
        if (picked.length >= totalNeeded) break;
        final list = byCategory[cat]!;
        for (final p in list) {
          if (usedIds.contains(p.id)) continue;
          picked.add(p);
          usedIds.add(p.id);
          break;
        }
      }
      // Kategori tükendiyse kalan placelarla devam et
      if (picked.length < totalNeeded && attempts > places.length) {
        for (final p in places) {
          if (usedIds.contains(p.id)) continue;
          picked.add(p);
          usedIds.add(p.id);
          if (picked.length >= totalNeeded) break;
        }
        break;
      }
    }

    // 5) Günlere böl
    final itinerary = <TripDay>[];
    for (int d = 0; d < days; d++) {
      final start = d * perDay;
      final end = (start + perDay).clamp(0, picked.length);
      if (start >= picked.length) break;
      itinerary.add(TripDay(
        dayNumber: d + 1,
        places: picked.sublist(start, end),
      ));
    }

    return TripPlan(
      city: matchedCity,
      days: itinerary.length,
      itinerary: itinerary,
      summary: _generateSummary(matchedCity, itinerary),
    );
  }

  static int _parseDays(String text) {
    // "2 gün", "3 günlük", "5 day", "haftasonu", "hafta sonu"
    final patterns = [
      RegExp(r'(\d+)\s*g[üu]n'),
      RegExp(r'(\d+)\s*day'),
      RegExp(r'(\d+)\s*tag'), // German
      RegExp(r'(\d+)\s*jour'), // French
      RegExp(r'(\d+)\s*день'), // Russian
      RegExp(r'(\d+)\s*يوم'), // Arabic
    ];
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        final n = int.tryParse(m.group(1) ?? '');
        if (n != null && n > 0 && n <= 7) return n;
      }
    }
    // Hafta sonu = 2 gün
    if (text.contains('haftasonu') ||
        text.contains('hafta sonu') ||
        text.contains('weekend') ||
        text.contains('wochenende')) {
      return 2;
    }
    // Default: 2 gün
    return 2;
  }

  static String _generateSummary(City city, List<TripDay> days) {
    final totalPlaces = days.fold<int>(0, (s, d) => s + d.places.length);
    return '${city.name} için ${days.length} günlük rota — toplam $totalPlaces seçili mekan';
  }

  // ─── Trip Wizard için ────────────────────────────────────────────

  static const _interestCategories = <String, List<String>>{
    'Tarih & Kültür': ['tarih', 'müze', 'tarihi', 'kültür', 'arkeoloji', 'cami', 'kilise', 'saray', 'kale'],
    'Doğa & Açık Hava': ['doğa', 'park', 'göl', 'plaj', 'dağ', 'orman', 'şelale', 'mağara', 'kanyon'],
    'Gastronomi': ['restoran', 'kafe', 'çarşı', 'pazar', 'market', 'yemek', 'mutfak'],
    'Sanat & Müzeler': ['müze', 'galeri', 'sanat', 'sergi', 'tiyatro', 'opera'],
    'Aktif & Macera': ['spor', 'yürüyüş', 'macera', 'tırmanış', 'bisiklet', 'rafting'],
    'Romantik': ['sahil', 'vadi', 'plaj', 'orman', 'gün batımı', 'göl'],
  };

  static Future<TripPlan?> planWithFilters({
    required City city,
    required int days,
    required String budget,
    required List<String> interests,
  }) async {
    final places = await DatabaseService.getPlacesByCity(city.id);
    if (places.isEmpty) {
      return TripPlan(city: city, days: days, itinerary: const [], summary: '');
    }

    List<Place> sorted = List.from(places);

    // Bütçe sıralaması
    if (budget == 'ekonomik') {
      sorted.sort((a, b) {
        if (a.isFree && !b.isFree) return -1;
        if (!a.isFree && b.isFree) return 1;
        return b.rating.compareTo(a.rating);
      });
    } else if (budget == 'lüks') {
      sorted.sort((a, b) {
        if (!a.isFree && b.isFree) return -1;
        if (a.isFree && !b.isFree) return 1;
        return b.rating.compareTo(a.rating);
      });
    } else {
      sorted.sort((a, b) => b.rating.compareTo(a.rating));
    }

    // İlgi alanı önceliklendirmesi
    if (interests.isNotEmpty) {
      final keywords = <String>[];
      for (final interest in interests) {
        keywords.addAll(_interestCategories[interest] ?? []);
      }
      sorted.sort((a, b) {
        final cat = a.category.toLowerCase();
        final bCat = b.category.toLowerCase();
        final aMatch = keywords.any((k) => cat.contains(k));
        final bMatch = keywords.any((k) => bCat.contains(k));
        if (aMatch && !bMatch) return -1;
        if (!aMatch && bMatch) return 1;
        return 0;
      });
    }

    const perDay = 4;
    final itinerary = <TripDay>[];
    for (int d = 0; d < days; d++) {
      final start = d * perDay;
      if (start >= sorted.length) break;
      final end = (start + perDay).clamp(0, sorted.length);
      itinerary.add(TripDay(dayNumber: d + 1, places: sorted.sublist(start, end)));
    }

    final budgetLabel = {'ekonomik': '💰 Ekonomik', 'orta': '💳 Orta Bütçe', 'lüks': '✨ Lüks'}[budget] ?? '';
    final interestLabel = interests.isEmpty ? '' : ' · ${interests.join(', ')}';
    final total = itinerary.fold<int>(0, (s, d) => s + d.places.length);
    final summary = '${city.name} · ${itinerary.length} gün · $budgetLabel$interestLabel — $total mekan';

    return TripPlan(
      city: city,
      days: itinerary.length,
      itinerary: itinerary,
      summary: summary,
    );
  }

  static Future<List<City>> _getCities() async {
    if (_citiesCache != null) return _citiesCache!;
    try {
      _citiesCache = await DatabaseService.getCities();
      return _citiesCache!;
    } catch (_) {
      return const [];
    }
  }
}

/// Bir gezi planı
class TripPlan {
  final City city;
  final int days;
  final List<TripDay> itinerary;
  final String summary;

  const TripPlan({
    required this.city,
    required this.days,
    required this.itinerary,
    required this.summary,
  });
}

/// Bir günün rotası
class TripDay {
  final int dayNumber;
  final List<Place> places;

  const TripDay({required this.dayNumber, required this.places});

  /// Gün dilimleri etiketi: Sabah / Öğlen / Öğleden sonra / Akşam
  String slotLabel(int index) {
    const slots = ['🌅 Sabah', '☕ Öğlen', '🌞 Öğleden sonra', '🌆 Akşam'];
    if (index >= slots.length) return '📍 ${index + 1}';
    return slots[index];
  }
}
