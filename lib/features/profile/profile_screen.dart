import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/design_tokens.dart';
import '../../shared/layout/bottom_nav.dart';
import '../../shared/layout/nav_destinations.dart';
import '../gamification/badge_service.dart';

/// Profil sayfası — iOS Ayarlar tarzı düz liste (giriş sonrası yeşil sistem).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final stats = await BadgeService.getStats();
    if (mounted) setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '';
    final isWide = MediaQuery.of(context).size.width > 768;

    final body = user == null
        ? _buildLoginRequired()
        : ListView(
            padding: const EdgeInsets.symmetric(vertical: DT.s16),
            children: [
              _summaryCard(email),
              const SizedBox(height: DT.s24),
              _statsRow(),
              const SizedBox(height: DT.s24),
              _sectionHeader(I18n.t('ah.profile.discovery')),
              _row(Icons.favorite_border, I18n.t('ah.drawer.favorites'), () => context.push('/favorites'),
                  color: DT.catFood),
              _row(Icons.route_outlined, I18n.t('ah.profile.myRoutes'), () => context.push('/trip-wizard'),
                  color: DT.primary),
              _row(Icons.history, I18n.t('ah.profile.visitHistory'), () => context.push('/activity'),
                  color: DT.catNature),
              _row(Icons.bar_chart_outlined, I18n.t('ah.profile.stats'), () => context.push('/stats'),
                  color: DT.catCastle),
              _sectionHeader(I18n.t('ah.profile.preferences')),
              _row(Icons.book_outlined, I18n.t('ah.profile.diaries'), () => context.push('/diaries'),
                  color: DT.catMosque),
              _row(Icons.notifications_outlined, I18n.t('ah.nav.notifications'),
                  () => context.push('/notifications'), color: DT.primary),
              _sectionHeader(I18n.t('ah.drawer.support')),
              _row(Icons.add_location_alt_outlined, I18n.t('ah.profile.suggestPlace'),
                  () => context.push('/suggest'), color: DT.catNature),
              _row(Icons.info_outline, I18n.t('ah.profile.about'), _showAbout,
                  color: DT.textSecondary),
              const SizedBox(height: DT.s24),
              _logoutLink(),
              const SizedBox(height: DT.s32),
            ],
          );

    return Scaffold(
      backgroundColor: DT.bg,
      appBar: AppBar(
        title: Text(I18n.t('ah.nav.profile'), style: DT.t16),
        backgroundColor: DT.surface,
        foregroundColor: DT.textMain,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(bottom: DT.side),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DT.textMain),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: body,
      bottomNavigationBar:
          isWide ? null : const BottomNav(currentRoute: '/profile'),
    );
  }

  Widget _summaryCard(String email) {
    final name = email.isNotEmpty ? email.split('@').first : I18n.t('ah.drawer.traveler');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DT.s16),
      child: Container(
        padding: const EdgeInsets.all(DT.s16),
        decoration: BoxDecoration(
          color: DT.surface,
          borderRadius: DT.brCard,
          border: DT.boxBorder,
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: DT.primary,
              child: Text(avatarInitials(email),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 24, fontWeight: DT.wMedium)),
            ),
            const SizedBox(height: DT.s12),
            Text(name, style: DT.t16),
            const SizedBox(height: 2),
            Text(email, style: DT.muted12),
            const SizedBox(height: DT.s12),
            OutlinedButton.icon(
              onPressed: _editProfile,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text(I18n.t('ah.profile.edit')),
              style: OutlinedButton.styleFrom(
                foregroundColor: DT.primary,
                side: const BorderSide(color: DT.primary),
                minimumSize: const Size(0, 32),
                shape: const RoundedRectangleBorder(borderRadius: DT.brSmall),
                textStyle: const TextStyle(fontSize: 13, fontWeight: DT.wMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsRow() {
    final visits = _stats?.uniquePlaces ?? 0;
    final total = _stats?.totalVisits ?? 0;
    final cats = _stats?.byCategory.length ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DT.s16),
      child: Row(
        children: [
          _metric(visits.toString(), I18n.t('ah.profile.metricPlaces')),
          _metric(total.toString(), I18n.t('ah.profile.metricVisits')),
          _metric(cats.toString(), I18n.t('ah.profile.metricCategories')),
        ],
      ),
    );
  }

  Widget _metric(String value, String label) => Expanded(
        child: Column(
          children: [
            Text(value, style: DT.t20),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 12, color: DT.textMuted)),
          ],
        ),
      );

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(DT.s16, DT.s24, DT.s16, DT.s8),
        child: Text(title.toUpperCase(),
            style: const TextStyle(
                fontSize: 12, color: DT.textMuted, fontWeight: DT.wMedium)),
      );

  Widget _row(IconData icon, String label, VoidCallback onTap,
      {required Color color}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 52,
        color: DT.surface,
        padding: const EdgeInsets.symmetric(horizontal: DT.s16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: DT.s12),
            Expanded(child: Text(label, style: DT.t14)),
            const Icon(Icons.chevron_right, size: 18, color: DT.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _logoutLink() => Center(
        child: TextButton(
          onPressed: () async {
            await Supabase.instance.client.auth.signOut();
            if (mounted) context.go('/');
          },
          child: Text(I18n.t('ah.common.logout'),
              style: const TextStyle(
                  color: DT.danger, fontSize: 14, fontWeight: DT.wMedium)),
        ),
      );

  void _editProfile() {
    final ctrl = TextEditingController(
      text: Supabase.instance.client.auth.currentUser?.userMetadata?['name']
              as String? ??
          '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DT.surface,
        title: Text(I18n.t('ah.profile.edit'), style: DT.t16),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: I18n.t('ah.profile.displayName'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(I18n.t('common.cancel'),
                style: const TextStyle(color: DT.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              try {
                await Supabase.instance.client.auth.updateUser(
                  UserAttributes(data: {'name': name}),
                );
              } catch (_) {}
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(I18n.t('ah.profile.updated'))),
                );
              }
            },
            child: Text(I18n.t('common.save'),
                style: const TextStyle(color: DT.primary, fontWeight: DT.wMedium)),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Travixx',
      applicationVersion: '1.0.0',
      applicationLegalese: I18n.t('ah.profile.legalese'),
    );
  }

  Widget _buildLoginRequired() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_outline, size: 48, color: DT.textMuted),
            const SizedBox(height: DT.s16),
            Text(I18n.t('ah.profile.loginRequired'), style: DT.t14),
            const SizedBox(height: DT.s16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              style: ElevatedButton.styleFrom(backgroundColor: DT.primary),
              child: Text(I18n.t('nav.login')),
            ),
          ],
        ),
      );
}
