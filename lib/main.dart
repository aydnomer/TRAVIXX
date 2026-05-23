import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_constants.dart';
import 'core/i18n/i18n.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/router.dart';
import 'features/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  await I18n.load();
  await AppTheme.load();
  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );
  // İlk açılışta onboarding gösterilsin
  final seenOnboarding = await OnboardingScreen.hasBeenSeen();
  // Onboarding görülmediyse router'ı /onboarding ile başlat
  if (!seenOnboarding) {
    appRouter.go('/onboarding');
  }
  runApp(const TravixxApp());
}

class TravixxApp extends StatelessWidget {
  const TravixxApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Dil değişimine reaktif — tüm app yeniden render olur
    return ValueListenableBuilder<String>(
      valueListenable: I18n.language,
      builder: (context, lang, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: AppTheme.mode,
          builder: (context, themeMode, _) {
            return MaterialApp.router(
              key: ValueKey('app_${lang}_${themeMode.name}'),
              title: 'Travixx',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              routerConfig: appRouter,
              builder: (context, child) => Directionality(
                textDirection:
                    I18n.isRtl(lang) ? TextDirection.rtl : TextDirection.ltr,
                child: child ?? const SizedBox(),
              ),
            );
          },
        );
      },
    );
  }
}
