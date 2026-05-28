import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../gamification/badge_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserStats? _stats;
  List<BadgeInfo> _earnedBadges = const [];
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _statsLoading = false);
      return;
    }
    final stats = await BadgeService.getStats();
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _earnedBadges = BadgeService.getEarnedBadges(stats);
      _statsLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(I18n.t('profile.title')),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: user == null
          ? _buildLoginRequired(context)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildAvatar(user),
                  const SizedBox(height: 16),
                  if (_stats != null) _buildStatsRow(_stats!),
                  const SizedBox(height: 16),
                  if (_stats != null) _buildLevelCard(_stats!),
                  const SizedBox(height: 16),
                  _buildBadgesSection(),
                  const SizedBox(height: 16),
                  _buildInfoCard(user),
                  const SizedBox(height: 16),
                  _buildMenuCard(context),
                  const SizedBox(height: 16),
                  _buildLogoutButton(context),
                ],
              ),
            ),
    );
  }

  // ── Gezgin Seviyesi Kartı ─────────────────────────────────────

  Widget _buildLevelCard(UserStats stats) {
    final lv = TravelerLevel.from(stats);
    final color = Color(lv.colorValue);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, Color.lerp(AppTheme.primary, color, 0.35)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst satır: emoji + seviye bilgisi + level badge
          Row(
            children: [
              Text(lv.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lv.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      lv.isMax
                          ? 'Maksimum seviyeye ulaştın! 🎉'
                          : '${lv.requiredXP - lv.currentXP} mekan daha → sonraki seviye',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Text(
                  'Lv. ${lv.level}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${lv.currentXP} / ${lv.requiredXP} mekan',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '${(lv.progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: lv.progress,
                        minHeight: 10,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Hızlı istatistik şeridi: Ziyaret + Mekan + Rozet sayıları
  Widget _buildStatsRow(UserStats stats) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          _statCol(stats.totalVisits.toString(), I18n.t('badge.stats.visits')),
          _statDivider(),
          _statCol(
              stats.uniquePlaces.toString(), I18n.t('badge.stats.places')),
          _statDivider(),
          _statCol(_earnedBadges.length.toString(), I18n.t('badge.title')),
        ],
      ),
    );
  }

  Widget _statCol(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentOrange,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(
        width: 1,
        height: 32,
        color: AppTheme.cardBorder,
      );

  Widget _buildBadgesSection() {
    if (_statsLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final all = BadgeService.allBadges;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium,
                  size: 18, color: AppTheme.accentOrange),
              const SizedBox(width: 8),
              Text(
                I18n.t('badge.title'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                '${_earnedBadges.length}/${all.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: all.map((b) => _badgeChip(b)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _badgeChip(BadgeInfo b) {
    final earned = _stats != null && b.isEarned(_stats!);
    final tierColor = switch (b.tier) {
      BadgeTier.bronze => const Color(0xFFCD7F32),
      BadgeTier.silver => const Color(0xFF94A3B8),
      BadgeTier.gold => const Color(0xFFEAB308),
    };

    // İlerleme hesabı (kazanılmamış için)
    double progress = 0.0;
    String progressLabel = '';
    if (!earned && _stats != null) {
      if (b.requiredUniquePlaces != null) {
        final req = b.requiredUniquePlaces!;
        progress = (_stats!.uniquePlaces / req).clamp(0.0, 1.0);
        progressLabel = '${_stats!.uniquePlaces}/$req';
      } else if (b.requiredCategoryCount != null &&
          b.requiredCategory != null) {
        final req = b.requiredCategoryCount!;
        final cur = _stats!.byCategory[b.requiredCategory!] ?? 0;
        progress = (cur / req).clamp(0.0, 1.0);
        progressLabel = '$cur/$req';
      }
    }

    return GestureDetector(
      onTap: () => _showBadgeDetail(b, earned),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
        decoration: BoxDecoration(
          color: earned
              ? tierColor.withValues(alpha: 0.12)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: earned ? tierColor : Colors.grey.shade300,
            width: earned ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: earned ? 1.0 : 0.3,
                  child:
                      Text(b.emoji, style: const TextStyle(fontSize: 26)),
                ),
                if (earned)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: tierColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          size: 9, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              I18n.t(b.titleKey),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: earned ? tierColor : Colors.grey,
              ),
            ),
            // Kazanılmamışsa ilerleme çubuğu
            if (!earned && progressLabel.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                progressLabel,
                style: const TextStyle(
                    fontSize: 8, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: Colors.grey.shade200,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(tierColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showBadgeDetail(BadgeInfo b, bool earned) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Text(b.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                I18n.t(b.titleKey),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(I18n.t(b.descKey)),
            const SizedBox(height: 12),
            if (!earned)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      I18n.t('badge.locked'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(I18n.t('common.cancel')),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(User user) {
    final initial = user.email != null && user.email!.isNotEmpty
        ? user.email![0].toUpperCase()
        : '?';
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppTheme.accentOrange, AppTheme.gold],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentOrange.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          user.email?.split('@')[0] ?? I18n.t('profile.travelerName'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.email ?? '',
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(User user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            I18n.t('profile.accountInfo'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.email_outlined, I18n.t('profile.email'),
              user.email ?? '-'),
          const SizedBox(height: 8),
          _infoRow(
            Icons.calendar_today_outlined,
            I18n.t('profile.memberSince'),
            _formatDate(user.createdAt),
          ),
          const SizedBox(height: 8),
          _infoRow(
            Icons.verified_user_outlined,
            I18n.t('profile.status'),
            user.emailConfirmedAt != null
                ? I18n.t('profile.verified')
                : I18n.t('profile.unverified'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          _menuTile(
            icon: Icons.favorite_outline,
            label: I18n.t('profile.myFavorites'),
            onTap: () => context.push('/favorites'),
          ),
          const Divider(height: 1, indent: 56),
          _menuTile(
            icon: Icons.location_city_outlined,
            label: I18n.t('profile.cities'),
            onTap: () => context.push('/cities'),
          ),
          const Divider(height: 1, indent: 56),
          _menuTile(
            icon: Icons.bar_chart,
            label: I18n.t('stats.title'),
            onTap: () => context.push('/stats'),
          ),
          const Divider(height: 1, indent: 56),
          _menuTile(
            icon: Icons.timeline,
            label: I18n.t('activity.title'),
            onTap: () => context.push('/activity'),
          ),
          const Divider(height: 1, indent: 56),
          _menuTile(
            icon: Icons.account_balance_wallet_outlined,
            label: I18n.t('budget.menuLabel'),
            onTap: () => context.push('/budget'),
          ),
          const Divider(height: 1, indent: 56),
          _menuTile(
            icon: Icons.luggage_outlined,
            label: I18n.t('packing.menuLabel'),
            onTap: () => context.push('/packing'),
          ),
          const Divider(height: 1, indent: 56),
          _menuTile(
            icon: Icons.workspace_premium_outlined,
            label: I18n.t('topRated.title'),
            onTap: () => context.push('/top-rated'),
          ),
          const Divider(height: 1, indent: 56),
          _menuTile(
            icon: Icons.book_outlined,
            label: I18n.t('diary.menuLabel'),
            onTap: () => context.push('/diaries'),
          ),
          const Divider(height: 1, indent: 56),
          // Dark mode toggle
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppTheme.mode,
            builder: (context, mode, _) {
              final isDark = mode == ThemeMode.dark;
              return ListTile(
                leading: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: AppTheme.primary,
                ),
                title: Text(
                  isDark ? I18n.t('theme.dark') : I18n.t('theme.light'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Switch(
                  value: isDark,
                  activeThumbColor: AppTheme.accentOrange,
                  onChanged: (_) => AppTheme.toggleDark(),
                ),
                onTap: () => AppTheme.toggleDark(),
              );
            },
          ),
          const Divider(height: 1, indent: 56),
          _menuTile(
            icon: Icons.add_location_alt_outlined,
            label: I18n.t('suggest.menuLabel'),
            onTap: () => context.push('/suggest'),
          ),
          const Divider(height: 1, indent: 56),
          _menuTile(
            icon: Icons.help_outline,
            label: I18n.t('profile.help'),
            onTap: () {},
            disabled: true,
          ),
          const Divider(height: 1, indent: 56),
          _menuTile(
            icon: Icons.settings_outlined,
            label: I18n.t('profile.settings'),
            onTap: () {},
            disabled: true,
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool disabled = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: disabled ? Colors.grey : AppTheme.primary,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: disabled ? Colors.grey : AppTheme.textPrimary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: disabled ? Colors.grey[300] : AppTheme.textSecondary,
      ),
      onTap: disabled ? null : onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context),
        icon: const Icon(Icons.logout, color: Colors.red),
        label: Text(
          I18n.t('logout.title'),
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Colors.red, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          I18n.t('logout.title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(I18n.t('logout.confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(I18n.t('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(I18n.t('logout.title')),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) context.go('/');
    }
  }

  Widget _buildLoginRequired(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_outline, size: 72, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            I18n.t('profile.loginPrompt'),
            style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.login),
            label: Text(I18n.t('nav.login')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('d MMMM yyyy', 'tr_TR').format(dt);
    } catch (_) {
      return isoDate.split('T').first;
    }
  }
}
