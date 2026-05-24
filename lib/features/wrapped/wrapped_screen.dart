import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/i18n.dart';
import '../gamification/badge_service.dart';

/// Travixx Wrapped — Spotify Wrapped tarzı yıllık özet.
/// 5 sayfalık story.
class WrappedScreen extends StatefulWidget {
  const WrappedScreen({super.key});

  @override
  State<WrappedScreen> createState() => _WrappedScreenState();
}

class _WrappedScreenState extends State<WrappedScreen> {
  final _ctrl = PageController();
  int _index = 0;
  UserStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await BadgeService.getStats();
    if (!mounted) return;
    setState(() {
      _stats = s;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    final s = _stats ?? UserStats.empty();
    final pages = _buildPages(s);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _ctrl,
            itemCount: pages.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => pages[i],
          ),
          // Üst — progress bar + kapatma
          Positioned(
            top: 40,
            left: 12,
            right: 12,
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: List.generate(pages.length, (i) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 3,
                          decoration: BoxDecoration(
                            color: i <= _index
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/profile'),
                ),
              ],
            ),
          ),
          // Tap zonelar (sol/sağ)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_index > 0) {
                      _ctrl.previousPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_index < pages.length - 1) {
                      _ctrl.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    } else {
                      Navigator.of(context).maybePop();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPages(UserStats s) {
    final topCat = _topEntry(s.byCategory);

    return [
      _storyPage(
        emoji: '🎉',
        big: '${DateTime.now().year}',
        title: I18n.t('wrapped.title'),
        subtitle: I18n.t('wrapped.subtitle'),
        gradient: const [Color(0xFF1A2744), Color(0xFFF97316)],
      ),
      _storyPage(
        emoji: '📍',
        big: s.uniquePlaces.toString(),
        title: I18n.t('wrapped.places.title'),
        subtitle: I18n.t('wrapped.places.subtitle'),
        gradient: const [Color(0xFF7C3AED), Color(0xFFEC4899)],
      ),
      _storyPage(
        emoji: '👣',
        big: s.totalVisits.toString(),
        title: I18n.t('wrapped.visits.title'),
        subtitle: I18n.t('wrapped.visits.subtitle'),
        gradient: const [Color(0xFF0891B2), Color(0xFF22D3EE)],
      ),
      if (topCat != null)
        _storyPage(
          emoji: _categoryEmoji(topCat.key),
          big: topCat.key,
          title: I18n.t('wrapped.topCategory.title'),
          subtitle: '${topCat.value} ${I18n.t('badge.stats.visits').toLowerCase()}',
          gradient: const [Color(0xFF14532D), Color(0xFF4ADE80)],
        ),
      _storyPage(
        emoji: '✨',
        big: BadgeService.getEarnedBadges(s).length.toString(),
        title: I18n.t('wrapped.badges.title'),
        subtitle: I18n.t('wrapped.badges.subtitle'),
        gradient: const [Color(0xFFEA580C), Color(0xFFEAB308)],
      ),
      _storyPage(
        emoji: '🎁',
        big: '🚀',
        title: I18n.t('wrapped.thankYou.title'),
        subtitle: I18n.t('wrapped.thankYou.subtitle'),
        gradient: const [Color(0xFF1E3A8A), Color(0xFF7C3AED)],
      ),
    ];
  }

  MapEntry<String, int>? _topEntry(Map<String, int> map) {
    if (map.isEmpty) return null;
    final entries = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return entries.first;
  }

  String _categoryEmoji(String cat) {
    switch (cat.toLowerCase()) {
      case 'müze':
        return '🖼️';
      case 'tarihi':
        return '🏛️';
      case 'doğa':
        return '🌿';
      case 'dini':
        return '🕌';
      case 'kültür':
        return '🎭';
      case 'manzara':
        return '🌅';
      default:
        return '📍';
    }
  }

  Widget _storyPage({
    required String emoji,
    required String big,
    required String title,
    required String subtitle,
    required List<Color> gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 120)),
              const SizedBox(height: 24),
              Text(
                big,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: big.length > 4 ? 36 : 72,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
