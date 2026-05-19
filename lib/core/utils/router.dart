import "package:go_router/go_router.dart";
import "../../features/auth/landing_screen.dart";
import "../../features/cities/home_screen.dart";
import "../../features/cities/cities_screen.dart";
import "../../features/places/places_screen.dart";

final GoRouter appRouter = GoRouter(
  initialLocation: "/",
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
  ],
);
