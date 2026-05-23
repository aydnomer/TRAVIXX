import 'dart:convert';
import 'package:http/http.dart' as http;

/// OpenStreetMap Overpass API — Travixx veritabanında olmayan
/// turistik mekanları aramak için ücretsiz Katman 2 servisi.
class OverpassPlace {
  final int osmId;
  final String name;
  final String? nameEn;
  final String? tourismType; // attraction, museum, viewpoint, etc.
  final String? historic;
  final double lat;
  final double lng;
  final String? city;
  final String? wikipedia;

  const OverpassPlace({
    required this.osmId,
    required this.name,
    this.nameEn,
    this.tourismType,
    this.historic,
    required this.lat,
    required this.lng,
    this.city,
    this.wikipedia,
  });

  String get emoji {
    if (tourismType == 'museum') return '🖼️';
    if (tourismType == 'viewpoint') return '🌄';
    if (historic == 'castle') return '🏰';
    if (historic == 'monument') return '🗿';
    if (historic == 'ruins') return '🏛️';
    if (historic == 'archaeological_site') return '⛏️';
    if (historic != null) return '🏛️';
    return '📍';
  }

  String get displayCategory {
    if (tourismType == 'museum') return 'Müze';
    if (tourismType == 'viewpoint') return 'Manzara';
    if (historic == 'castle') return 'Kale';
    if (historic == 'monument') return 'Anıt';
    if (historic == 'ruins') return 'Kalıntı';
    if (historic == 'archaeological_site') return 'Arkeolojik';
    if (historic != null) return 'Tarihi';
    if (tourismType != null) return 'Turistik';
    return 'Mekan';
  }
}

class OverpassService {
  static const String _endpoint = 'https://overpass-api.de/api/interpreter';

  /// Türkiye sınırları içinde isimle eşleşen turistik mekanları arar.
  /// Maksimum 20 sonuç döner.
  static Future<List<OverpassPlace>> searchTurkey(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    // Türkiye ülke alanı (ISO TR) içinde, isim regex match (case-insensitive)
    // Hem tourism hem historic etiketlerini kapsa
    final safeQ = _escapeRegex(q);
    final overpassQL = '''
[out:json][timeout:25];
area["ISO3166-1"="TR"]->.tr;
(
  node["name"~"$safeQ",i]["tourism"](area.tr);
  node["name"~"$safeQ",i]["historic"](area.tr);
  way["name"~"$safeQ",i]["tourism"](area.tr);
  way["name"~"$safeQ",i]["historic"](area.tr);
);
out center tags 20;
''';

    try {
      final res = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'User-Agent': 'Travixx/1.0',
            },
            body: 'data=${Uri.encodeComponent(overpassQL)}',
          )
          .timeout(const Duration(seconds: 25));

      if (res.statusCode != 200) return const [];
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final elements = json['elements'] as List? ?? const [];

      final places = <OverpassPlace>[];
      for (final el in elements) {
        final tags = (el['tags'] as Map?)?.cast<String, dynamic>() ?? const {};
        final name = tags['name'] as String?;
        if (name == null || name.isEmpty) continue;

        // node ise lat/lon, way ise center.lat/center.lon
        double? lat;
        double? lng;
        if (el['type'] == 'node') {
          lat = (el['lat'] as num?)?.toDouble();
          lng = (el['lon'] as num?)?.toDouble();
        } else if (el['type'] == 'way') {
          final center = el['center'] as Map?;
          lat = (center?['lat'] as num?)?.toDouble();
          lng = (center?['lon'] as num?)?.toDouble();
        }
        if (lat == null || lng == null) continue;

        places.add(OverpassPlace(
          osmId: (el['id'] as num).toInt(),
          name: name,
          nameEn: tags['name:en'] as String?,
          tourismType: tags['tourism'] as String?,
          historic: tags['historic'] as String?,
          lat: lat,
          lng: lng,
          city: tags['addr:city'] as String?,
          wikipedia: tags['wikipedia'] as String?,
        ));
      }
      return places;
    } catch (_) {
      return const [];
    }
  }

  /// Regex özel karakterlerini escape et (kullanıcı girdisini güvenli yap).
  static String _escapeRegex(String s) {
    return s.replaceAllMapped(
      RegExp(r'[.*+?^${}()|[\]\\]'),
      (m) => '\\${m[0]}',
    );
  }

  /// Verilen koordinatın belirli yarıçapı içindeki restoran/kafe/yemek
  /// noktalarını döner (Overpass amenity tag'leri).
  static Future<List<NearbyVenue>> nearbyFood({
    required double lat,
    required double lng,
    int radiusMeters = 1000,
    int limit = 20,
  }) async {
    final query = '''
[out:json][timeout:20];
(
  node["amenity"~"^(restaurant|cafe|fast_food|bar|pub|ice_cream|bakery)\$"](around:$radiusMeters,$lat,$lng);
);
out body $limit;
''';

    try {
      final response = await http
          .post(
            Uri.parse('https://overpass-api.de/api/interpreter'),
            body: {'data': query},
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) return const [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = data['elements'] as List? ?? [];

      final venues = <NearbyVenue>[];
      for (final el in elements) {
        final tags = el['tags'] as Map<String, dynamic>?;
        if (tags == null) continue;

        final name = tags['name'] as String?;
        if (name == null || name.isEmpty) continue;

        final amenity = tags['amenity'] as String? ?? 'restaurant';
        final venueLat = (el['lat'] as num?)?.toDouble();
        final venueLng = (el['lon'] as num?)?.toDouble();
        if (venueLat == null || venueLng == null) continue;

        // Düz mesafe hesaplama (basit, kısa mesafeler için yeterli)
        final dist = _quickDistance(lat, lng, venueLat, venueLng);

        venues.add(NearbyVenue(
          osmId: (el['id'] as num).toInt(),
          name: name,
          amenity: amenity,
          lat: venueLat,
          lng: venueLng,
          cuisine: tags['cuisine'] as String?,
          distanceMeters: dist.round(),
        ));
      }
      // Yakından uzağa sırala
      venues.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
      return venues;
    } catch (_) {
      return const [];
    }
  }

  /// Hızlı küresel mesafe (Haversine basitleştirilmiş — kısa mesafelerde yeterli)
  static double _quickDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const earthR = 6371000.0; // metre
    final dLat = (lat2 - lat1) * 3.14159265 / 180.0;
    final dLng = (lng2 - lng1) * 3.14159265 / 180.0;
    final a = dLat * dLat + dLng * dLng * 0.5;
    return earthR * 0.000001 * a.clamp(0, double.infinity) +
        earthR * (dLat.abs() + dLng.abs()) * 0.5;
  }
}

/// Yakındaki yemek mekanı
class NearbyVenue {
  final int osmId;
  final String name;
  final String amenity; // restaurant | cafe | fast_food | bar | ...
  final double lat;
  final double lng;
  final String? cuisine;
  final int distanceMeters;

  const NearbyVenue({
    required this.osmId,
    required this.name,
    required this.amenity,
    required this.lat,
    required this.lng,
    this.cuisine,
    required this.distanceMeters,
  });

  String get emoji {
    switch (amenity) {
      case 'cafe':
        return '☕';
      case 'fast_food':
        return '🍔';
      case 'bar':
      case 'pub':
        return '🍺';
      case 'ice_cream':
        return '🍦';
      case 'bakery':
        return '🥐';
      default:
        return '🍽️';
    }
  }

  String get typeLabel {
    switch (amenity) {
      case 'cafe':
        return 'Kafe';
      case 'fast_food':
        return 'Fast Food';
      case 'bar':
        return 'Bar';
      case 'pub':
        return 'Pub';
      case 'ice_cream':
        return 'Dondurma';
      case 'bakery':
        return 'Fırın';
      default:
        return 'Restoran';
    }
  }

  String get distanceText {
    if (distanceMeters < 100) return '<100m';
    if (distanceMeters < 1000) return '${distanceMeters}m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
  }

  /// Google Maps URL'i (tıklayınca yön tarifi alabilir)
  String get mapsUrl =>
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
}

