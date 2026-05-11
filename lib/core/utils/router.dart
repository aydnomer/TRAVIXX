import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/landing_screen.dart';
import '../../features/cities/home_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;
    final isLanding = state.matchedLocation == '/';
    if (!isLoggedIn && !isLanding) return '/';
    if (isLoggedIn && isLanding) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const LandingScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
  ],
);
