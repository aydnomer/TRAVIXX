import "dart:async";
import "package:flutter/foundation.dart";
import "package:go_router/go_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "../../features/auth/landing_screen.dart";
import "../../features/cities/home_screen.dart";
import "../../features/cities/cities_screen.dart";
import "../../features/places/places_screen.dart";
import "../../features/places/place_detail_screen.dart";
import "../../features/ai_planner/ai_chat_screen.dart";
import "../../features/favorites/favorites_screen.dart";
import "../../features/profile/profile_screen.dart";
import "../../features/collections/collection_detail_screen.dart";
import "../../features/collections/collections_screen.dart";
import "../../features/diary/diaries_screen.dart";
import "../../features/diary/diary_detail_screen.dart";
import "../../features/map/map_screen.dart";
import "../../features/activity/activity_screen.dart";
import "../../features/compare/compare_screen.dart";
import "../../features/mood/mood_screen.dart";
import "../../features/notifications/notifications_screen.dart";
import "../../features/onboarding/onboarding_screen.dart";
import "../../features/restaurants/restaurants_screen.dart";
import "../../features/stats/stats_screen.dart";
import "../../features/top_rated/top_rated_screen.dart";
import "../../features/trip_tools/budget_screen.dart";
import "../../features/trip_tools/packing_screen.dart";
import "../../features/wrapped/wrapped_screen.dart";
import "../../features/suggest/suggest_place_screen.dart";
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
    GoRoute(
      path: "/ai-chat",
      builder: (context, state) => const AiChatScreen(),
    ),
    GoRoute(
      path: "/suggest",
      builder: (context, state) => const SuggestPlaceScreen(),
    ),
    GoRoute(
      path: "/map",
      builder: (context, state) => const MapScreen(),
    ),
    GoRoute(
      path: "/collections",
      builder: (context, state) => const CollectionsScreen(),
    ),
    GoRoute(
      path: "/collection/:id",
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return CollectionDetailScreen(collectionId: id);
      },
    ),
    GoRoute(
      path: "/diaries",
      builder: (context, state) => const DiariesScreen(),
    ),
    GoRoute(
      path: "/diary/:id",
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return DiaryDetailScreen(diaryId: id);
      },
    ),
    GoRoute(
      path: "/restaurants",
      builder: (context, state) => const RestaurantsScreen(),
    ),
    GoRoute(
      path: "/onboarding",
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: "/notifications",
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: "/mood",
      builder: (context, state) {
        final mood = state.uri.queryParameters['m'];
        return MoodScreen(initialMood: mood);
      },
    ),
    GoRoute(
      path: "/activity",
      builder: (context, state) => const ActivityScreen(),
    ),
    GoRoute(
      path: "/top-rated",
      builder: (context, state) => const TopRatedScreen(),
    ),
    GoRoute(
      path: "/stats",
      builder: (context, state) => const StatsScreen(),
    ),
    GoRoute(
      path: "/wrapped",
      builder: (context, state) => const WrappedScreen(),
    ),
    GoRoute(
      path: "/budget",
      builder: (context, state) => const BudgetScreen(),
    ),
    GoRoute(
      path: "/packing",
      builder: (context, state) => const PackingScreen(),
    ),
    GoRoute(
      path: "/compare",
      builder: (context, state) => const CompareScreen(),
    ),
  ],
);
