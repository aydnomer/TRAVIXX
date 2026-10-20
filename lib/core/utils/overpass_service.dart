import 'dart:convert';
import 'package:http/http.dart' as http;

import '../i18n/i18n.dart';
import 'gps_service.dart';

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
    if (tourismType == 'museum') return I18n.t('cs.osm.museum');
    if (tourismType == 'viewpoint') return I18n.t('cs.osm.viewpoint');
    if (historic == 'castle') return I18n.t('cs.osm.castle');
    if (historic == 'monument') return I18n.t('cs.osm.monument');
    if (historic == 'ruins') return I18n.t('cs.osm.ruins');
    if (historic == 'archaeological_site') return I18n.t('cs.osm.archaeological');
    if (historic != null) return I18n.t('cs.osm.historic');
    if (tourismType != null) return I18n.t('cs.osm.tourist');
    return I18n.t('cs.osm.place');
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

        final dist =
            GpsService.distanceKm(lat, lng, venueLat, venueLng) * 1000;

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
        return I18n.t('cs.venue.cafe');
      case 'fast_food':
        return I18n.t('cs.venue.fastFood');
      case 'bar':
        return I18n.t('cs.venue.bar');
      case 'pub':
        return I18n.t('cs.venue.pub');
      case 'ice_cream':
        return I18n.t('cs.venue.iceCream');
      case 'bakery':
        return I18n.t('cs.venue.bakery');
      default:
        return I18n.t('cs.venue.restaurant');
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

