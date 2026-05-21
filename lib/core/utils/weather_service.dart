import 'dart:convert';
import 'package:http/http.dart' as http;

/// Open-Meteo API ile hava durumu.
/// - Ücretsiz, API key yok, sınırsız (rate-limit makul).
/// - Aynı konum için 30 dakika cache'lenir.
/// - Hata olursa null döner (UI sessizce gizler).
class WeatherService {
  /// Konum bazında cache (lat,lng → (weather, fetchedAt))
  static final Map<String, _CacheEntry> _cache = {};

  /// Belirli koordinat için anlık hava durumu.
  static Future<WeatherInfo?> currentWeather({
    required double lat,
    required double lng,
  }) async {
    final key = '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';
    final cached = _cache[key];
    if (cached != null && !cached.isStale) return cached.weather;

    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lng'
        '&current=temperature_2m,weather_code,wind_speed_10m'
        '&timezone=auto',
      );
      final res = await http
          .get(uri)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>?;
      if (current == null) return null;

      final weather = WeatherInfo(
        temperatureC: (current['temperature_2m'] as num?)?.toDouble() ?? 0,
        weatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
        windKmh: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0,
      );
      _cache[key] = _CacheEntry(weather, DateTime.now());
      return weather;
    } catch (_) {
      return null;
    }
  }
}

class WeatherInfo {
  final double temperatureC;
  final int weatherCode;
  final double windKmh;

  const WeatherInfo({
    required this.temperatureC,
    required this.weatherCode,
    required this.windKmh,
  });

  /// WMO weather code'una göre emoji ikonu.
  /// https://open-meteo.com/en/docs (weather_code tablosu)
  String get emoji {
    if (weatherCode == 0) return '☀️';        // clear
    if (weatherCode <= 2) return '🌤️';        // mainly clear / partly cloudy
    if (weatherCode == 3) return '☁️';        // overcast
    if (weatherCode >= 45 && weatherCode <= 48) return '🌫️'; // fog
    if (weatherCode >= 51 && weatherCode <= 57) return '🌦️'; // drizzle
    if (weatherCode >= 61 && weatherCode <= 67) return '🌧️'; // rain
    if (weatherCode >= 71 && weatherCode <= 77) return '🌨️'; // snow
    if (weatherCode >= 80 && weatherCode <= 82) return '🌧️'; // rain showers
    if (weatherCode >= 85 && weatherCode <= 86) return '🌨️'; // snow showers
    if (weatherCode >= 95) return '⛈️';       // thunderstorm
    return '🌡️';
  }
}

class _CacheEntry {
  final WeatherInfo weather;
  final DateTime fetchedAt;
  _CacheEntry(this.weather, this.fetchedAt);

  bool get isStale {
    return DateTime.now().difference(fetchedAt) > const Duration(minutes: 30);
  }
}
