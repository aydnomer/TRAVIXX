import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

/// GPS / konum servisi.
/// - Konum iznini ister, mevcut konumu döner.
/// - Haversine formülü ile iki nokta arası km hesaplar.
/// - Tahmini araç süresi (ortalama 50 km/s) verir.
class GpsService {
  static Position? _cachedPosition;

  /// Kullanıcının izin durumunu kontrol eder ve gerekirse ister.
  /// Konum dönerse `Position`, dönmezse null.
  static Future<Position?> getCurrentPosition({bool useCache = true}) async {
    if (useCache && _cachedPosition != null) return _cachedPosition;

    try {
      // Servis açık mı?
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      // İzin durumu
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return null;
      }
      if (perm == LocationPermission.deniedForever) return null;

      // Konum al (web ve mobilde çalışır)
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _cachedPosition = pos;
      return pos;
    } catch (_) {
      // Web'de izin reddi, mobile'da timeout vb. — sessiz başarısızlık
      return null;
    }
  }

  /// İki koordinat arasındaki mesafeyi km olarak döner (Haversine).
  static double distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const earthR = 6371.0; // km
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthR * c;
  }

  /// km'yi araba ile ortalama süre (dk) olarak tahmin eder.
  /// Şehir içi 30 km/s, şehir dışı 70 km/s karışımı: ~50 km/s.
  static int estimateMinutes(double km) {
    if (km <= 0) return 0;
    return (km / 50 * 60).round();
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);

  /// Cache'i temizler (örn. kullanıcı tekrar tazelemek istiyorsa).
  static void clearCache() => _cachedPosition = null;
}
