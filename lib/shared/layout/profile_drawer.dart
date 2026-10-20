import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/design_tokens.dart';
import 'nav_destinations.dart';

/// Web: sağdan 320px açılan profil/ayarlar drawer'ı.
/// Overlay rgba(0,0,0,0.3), slide animasyonu 150ms.
Future<void> showProfileDrawer(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: I18n.t('ah.nav.profile'),
    barrierColor: Colors.black.withValues(alpha: 0.3),
    transitionDuration: DT.anim,
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, __) {
      final slide = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));
      return Align(
        alignment: Alignment.centerRight,
        child: SlideTransition(
          position: slide,
          child: const _DrawerBody(),
        ),
      );
    },
  );
}

class _DrawerBody extends StatelessWidget {
  const _DrawerBody();

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '';
    final initials = avatarInitials(email);

    return Material(
      color: DT.surface,
      child: SizedBox(
        width: 320,
        height: double.infinity,
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Başlık
              Padding(
                padding: const EdgeInsets.all(DT.s24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: DT.primary,
                      child: Text(initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: DT.wMedium)),
                    ),
                    const SizedBox(width: DT.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(avatarInitials(email).length > 1
                              ? email.split('@').first
                              : I18n.t('ah.drawer.traveler'), style: DT.t16),
                          const SizedBox(height: 2),
                          Text(email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DT.muted12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: DT.border),
              _section(I18n.t('ah.drawer.account')),
              _row(context, Icons.edit_outlined, I18n.t('ah.profile.edit'), '/profile'),
              _section(I18n.t('ah.profile.discovery')),
              _row(context, Icons.favorite_border, I18n.t('ah.drawer.favorites'), '/favorites'),
              _row(context, Icons.route_outlined, I18n.t('ah.profile.myRoutes'), '/trip-wizard'),
              _row(context, Icons.history, I18n.t('ah.drawer.visitHistory'), '/activity'),
              _row(context, Icons.bar_chart_outlined, I18n.t('ah.profile.stats'), '/stats'),
              _section(I18n.t('ah.nav.explore')),
              _row(context, Icons.qr_code_scanner, I18n.t('ah.drawer.qrScan'), '/qr-scan'),
              _row(context, Icons.collections_bookmark_outlined, I18n.t('ah.drawer.collections'),
                  '/collections'),
              _row(context, Icons.mood_outlined, I18n.t('ah.drawer.mood'), '/mood'),
              _row(context, Icons.star_outline, I18n.t('ah.drawer.topRated'),
                  '/top-rated'),
              _row(context, Icons.restaurant_outlined, I18n.t('ah.drawer.restaurants'),
                  '/restaurants'),
              _row(context, Icons.play_circle_outline, I18n.t('ah.drawer.videos'),
                  '/videos'),
              _row(context, Icons.forum_outlined, I18n.t('ah.drawer.community'), '/community'),
              _section(I18n.t('ah.drawer.tripTools')),
              _row(context, Icons.account_balance_wallet_outlined,
                  I18n.t('ah.drawer.budget'), '/budget'),
              _row(context, Icons.luggage_outlined, I18n.t('ah.drawer.packing'), '/packing'),
              _row(context, Icons.compare_arrows, I18n.t('ah.drawer.compare'),
                  '/compare'),
              _row(context, Icons.hotel_outlined, I18n.t('ah.drawer.accommodation'), '/accommodation'),
              _row(context, Icons.qr_code_2, I18n.t('ah.drawer.qrPrint'), '/qr-print'),
              _section(I18n.t('ah.drawer.app')),
              _row(context, Icons.notifications_outlined, I18n.t('ah.nav.notifications'),
                  '/notifications'),
              _row(context, Icons.book_outlined, I18n.t('ah.profile.diaries'), '/diaries'),
              _section(I18n.t('ah.drawer.support')),
              _row(context, Icons.add_location_alt_outlined, I18n.t('ah.profile.suggestPlace'),
                  '/suggest'),
              const Divider(height: 1, color: DT.border),
              // Çıkış
              InkWell(
                onTap: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    context.go('/');
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DT.s24, vertical: DT.s16),
                  child: Row(
                    children: [
                      const Icon(Icons.logout, size: 20, color: DT.danger),
                      const SizedBox(width: DT.s12),
                      Text(I18n.t('ah.common.logout'),
                          style: const TextStyle(
                              fontSize: 14,
                              color: DT.danger,
                              fontWeight: DT.wMedium)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(DT.s24, DT.s16, DT.s24, DT.s8),
        child: Text(title.toUpperCase(),
            style: const TextStyle(
                fontSize: 12, color: DT.textMuted, fontWeight: DT.wMedium)),
      );

  Widget _row(
      BuildContext context, IconData icon, String label, String route) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        context.push(route);
      },
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: DT.s24, vertical: DT.s12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: DT.textSecondary),
            const SizedBox(width: DT.s12),
            Expanded(child: Text(label, style: DT.t14)),
            const Icon(Icons.chevron_right, size: 18, color: DT.textMuted),
          ],
        ),
      ),
    );
  }
}
