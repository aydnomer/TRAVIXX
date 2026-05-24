import '../utils/gps_service.dart';
import '../../features/places/place_model.dart';

/// Nearest Neighbor TSP — verilen mekanları başlangıç noktasından
/// en yakına gidecek şekilde sıralar.
///
/// O(n²) — küçük (10-20) listeler için yeterli. Optimal değil ama hızlı.
class RouteOptimizer {
  /// Verilen başlangıç noktasından başlayarak [places]'i en yakın komşu
  /// sırasıyla döner. lat/lng'si olmayan yerler atlanır.
  static OptimizedRoute optimize({
    required double startLat,
    required double startLng,
    required List<Place> places,
  }) {
    final remaining = places
        .where((p) => p.latitude != null && p.longitude != null)
        .toList();

    if (remaining.isEmpty) {
      return const OptimizedRoute(
        ordered: [],
        totalKm: 0,
        legDistancesKm: [],
      );
    }

    final ordered = <Place>[];
    final legs = <double>[];
    double totalKm = 0;
    double currentLat = startLat;
    double currentLng = startLng;

    while (remaining.isNotEmpty) {
      // En yakın mekanı bul
      Place? nearest;
      double minDist = double.infinity;
      for (final p in remaining) {
        final d = GpsService.distanceKm(
          currentLat,
          currentLng,
          p.latitude!,
          p.longitude!,
        );
        if (d < minDist) {
          minDist = d;
          nearest = p;
        }
      }
      if (nearest == null) break;
      ordered.add(nearest);
      legs.add(minDist);
      totalKm += minDist;
      currentLat = nearest.latitude!;
      currentLng = nearest.longitude!;
      remaining.remove(nearest);
    }

    return OptimizedRoute(
      ordered: ordered,
      totalKm: totalKm,
      legDistancesKm: legs,
    );
  }
}

class OptimizedRoute {
  final List<Place> ordered;
  final double totalKm;
  final List<double> legDistancesKm;
  const OptimizedRoute({
    required this.ordered,
    required this.totalKm,
    required this.legDistancesKm,
  });

  int get estimatedMinutes => GpsService.estimateMinutes(totalKm);
}
