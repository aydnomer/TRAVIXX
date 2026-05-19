import "dart:async";
import "package:flutter/foundation.dart";
import "package:go_router/go_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "../../features/auth/landing_screen.dart";
import "../../features/cities/home_screen.dart";
import "../../features/cities/cities_screen.dart";
import "../../features/places/places_screen.dart";
import "../../features/places/place_detail_screen.dart";
import "../../features/favorites/favorites_screen.dart";
import "../../features/profile/profile_screen.dart";
import "../../features/qr_scanner/qr_scanner_screen.dart";
import "../../features/search/search_screen.dart";

/// Supabase auth state değişimlerinde router'ı tetiklemek için.
class _AuthRefreshListenable extends ChangeNotifier {
  late final StreamSubscription _sub;
  _AuthRefreshListenable() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _authRefresh = _AuthRefreshListenable();

final GoRouter appRouter = GoRouter(
  initialLocation: "/",
  refreshListenable: _authRefresh,
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final loc = state.matchedLocation;

    // /home'a gitmek için oturum şart
    if (loc == "/home" && session == null) return "/";

    // Zaten oturum açıksa, landing'de takılma — /home'a yönlendir
    if (loc == "/" && session != null) return "/home";

    return null;
  },
  routes: [
    GoRoute(
      path: "/",
      builder: (context, state) => const LandingScreen(),
    ),
    GoRoute(
      path: "/home",
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: "/cities",
      builder: (context, state) => const CitiesScreen(),
    ),
    GoRoute(
      path: "/city/:id",
      builder: (context, state) {
        final cityId = state.pathParameters["id"]!;
        final cityName = state.extra as String? ?? "Sehir";
        return PlacesScreen(cityId: cityId, cityName: cityName);
      },
    ),
    GoRoute(
      path: "/place/:id",
      builder: (context, state) {
        final placeId = state.pathParameters["id"]!;
        return PlaceDetailScreen(placeId: placeId);
      },
    ),
    GoRoute(
      path: "/favorites",
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(
      path: "/profile",
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: "/qr-scan",
      builder: (context, state) => const QrScannerScreen(),
    ),
    GoRoute(
      path: "/search",
      builder: (context, state) {
        final q = state.uri.queryParameters['q'] ?? '';
        return SearchScreen(initialQuery: q);
      },
    ),
  ],
);
