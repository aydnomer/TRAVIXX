import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../gamification/badge_service.dart';

/// Kullanıcının kişisel gezi istatistikleri dashboard'u.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  UserStats? _stats;
  double? _totalKm; // tahmini toplam yürünen mesafe
  String? _topCategory;
  String? _topCity;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final stats = await BadgeService.getStats();

    // En çok ziyaret edilen kategori
    String? topCat;
    int max = 0;
    stats.byCategory.forEach((cat, count) {
      if (count > max) {
        max = count;
        topCat = cat;
      }
    });

    // Top city — visits + places.city_id join
    String? topCity;
    try {
      final response = await Supabase.instance.client
          .from('visits')
          .select('places(city_id, cities(name))')
          .eq('user_id', user.id);
      final cityCount = <String, int>{};
      for (final v in (response as List)) {
        final places = (v as Map)['places'];
        if (places is Map) {
          final cities = places['cities'];
          if (cities is Map && cities['name'] is String) {
            final name = cities['name'] as String;
            cityCount[name] = (cityCount[name] ?? 0) + 1;
          }
        }
      }
      int max = 0;
      cityCount.forEach((k, v) {
        if (v > max) {
          max = v;
          topCity = k;
        }
      });
    } catch (_) {}

    // Total km — basit tahmin: her ziyaret ~5 km
    final estimatedKm = stats.uniquePlaces * 5.0;

    if (!mounted) return;
    setState(() {
      _stats = stats;
      _topCategory = topCat;
      _topCity = topCity;
      _totalKm = estimatedKm;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(I18n.t('stats.title')),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/profile'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Travixx Wrapped',
            onPressed: () => context.push('/wrapped'),
          ),
        ],
      ),
      body: user == null
          ? Center(child: Text(I18n.t('stats.loginRequired')))
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroStats(),
                      const SizedBox(height: 20),
                      _buildCategoryBreakdown(),
                      const SizedBox(height: 20),
                      _buildHighlights(),
                      const SizedBox(height: 20),
                      _buildWrappedButton(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeroStats() {
    final s = _stats ?? UserStats.empty();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _heroStat(s.totalVisits.toString(), I18n.t('badge.stats.visits'))),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(child: _heroStat(s.uniquePlaces.toString(), I18n.t('badge.stats.places'))),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(child: _heroStat('~${_totalKm?.toStringAsFixed(0) ?? 0}', 'km')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown() {
    final s = _stats;
    if (s == null || s.byCategory.isEmpty) return const SizedBox.shrink();
    final total = s.totalVisits;
    final entries = s.byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
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
            I18n.t('stats.byCategory'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          ...entries.map((e) => _categoryBar(e.key, e.value, total)),
        ],
      ),
    );
  }

  Widget _categoryBar(String name, int count, int total) {
    final pct = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$count (${(pct * 100).toStringAsFixed(0)}%)',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AppTheme.cardBorder,
              valueColor: AlwaysStoppedAnimation<Color>(
                  HSVColor.fromAHSV(1, (pct * 360) % 360, 0.5, 0.8).toColor()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlights() {
    return Container(
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
            I18n.t('stats.highlights'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          if (_topCategory != null)
            _highlightRow('🏆', I18n.t('stats.topCategory'), _topCategory!),
          if (_topCity != null)
            _highlightRow('🌆', I18n.t('stats.topCity'), _topCity!),
        ],
      ),
    );
  }

  Widget _highlightRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWrappedButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => context.push('/wrapped'),
        icon: const Icon(Icons.auto_awesome, size: 18),
        label: Text(
          I18n.t('stats.viewWrapped'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentOrange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
