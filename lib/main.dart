import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_constants.dart';
import 'core/i18n/i18n.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  await I18n.load();
  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );
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
        return MaterialApp.router(
          // Dil değişince tüm sayfa ağacını yeniden inşa et
          key: ValueKey('app_$lang'),
          title: 'Travixx',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: appRouter,
          // Directionality MaterialApp İÇİNDE — Material widget'ları
          // (TextField, PopupMenuButton) doğru context'i bulur, RTL de
          // çalışır. Dışa sarmak Material'ı bozuyor.
          builder: (context, child) => Directionality(
            textDirection:
                I18n.isRtl(lang) ? TextDirection.rtl : TextDirection.ltr,
            child: child ?? const SizedBox(),
          ),
        );
      },
    );
  }
}
