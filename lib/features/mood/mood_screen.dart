import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/database_service.dart';
import '../places/place_model.dart';

/// 6 ruh haline göre mekan keşif ekranı.
/// Romantik, Macera, Aile, Solo, Dinlendirici, Kültürel
class MoodScreen extends StatefulWidget {
  final String? initialMood;
  const MoodScreen({super.key, this.initialMood});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  String? _selected;
  List<Place> _allPlaces = const [];
  bool _loading = true;

  static const _moods = [
    _Mood(
      id: 'romantic',
      emoji: '💕',
      labelKey: 'mood.romantic',
      gradient: [Color(0xFF831843), Color(0xFFEC4899)],
      keywords: ['kapadokya', 'göreme', 'mardin', 'safranbolu', 'amasya', 'galata'],
      categories: ['Manzara', 'Kültür'],
    ),
    _Mood(
      id: 'adventure',
      emoji: '🎒',
      labelKey: 'mood.adventure',
      gradient: [Color(0xFF7C2D12), Color(0xFFEA580C)],
      keywords: ['dağ', 'kanyon', 'şelale', 'mağara', 'yamaç paraşütü', 'rafting'],
      categories: ['Doğa', 'Manzara'],
    ),
    _Mood(
      id: 'family',
      emoji: '👨‍👩‍👧‍👦',
      labelKey: 'mood.family',
      gradient: [Color(0xFF134E4A), Color(0xFF10B981)],
      keywords: ['park', 'müze', 'akvaryum', 'hayvanat', 'oyun'],
      categories: ['Müze', 'Eğlence'],
    ),
    _Mood(
      id: 'solo',
      emoji: '🧘',
      labelKey: 'mood.solo',
      gradient: [Color(0xFF1E3A8A), Color(0xFF60A5FA)],
      keywords: ['manastır', 'cami', 'türbe', 'kütüphane', 'sahil', 'göl'],
      categories: ['Dini', 'Doğa'],
    ),
    _Mood(
      id: 'relaxing',
      emoji: '🌊',
      labelKey: 'mood.relaxing',
      gradient: [Color(0xFF0891B2), Color(0xFF67E8F9)],
      keywords: ['plaj', 'göl', 'kaplıca', 'lagün', 'sahil', 'pamukkale'],
      categories: ['Doğa'],
    ),
    _Mood(
      id: 'cultural',
      emoji: '🏛️',
      labelKey: 'mood.cultural',
      gradient: [Color(0xFF78350F), Color(0xFFCA8A04)],
      keywords: ['müze', 'antik', 'tarihi', 'kale', 'saray', 'cami'],
      categories: ['Tarihi', 'Müze', 'Kültür'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initialMood;
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await DatabaseService.getAllPlaces();
      if (!mounted) return;
      setState(() {
        _allPlaces = all;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Place> _placesForMood(_Mood m) {
    final results = _allPlaces.where((p) {
      final n = '${p.name} ${p.description}'.toLowerCase();
      final kwMatch = m.keywords.any((k) => n.contains(k));
      final catMatch = m.categories.contains(p.category);
      return kwMatch || catMatch;
    }).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return results.take(30).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentMood = _selected == null
        ? null
        : _moods.firstWhere(
            (m) => m.id == _selected,
            orElse: () => _moods.first,
          );
    final places = currentMood == null ? <Place>[] : _placesForMood(currentMood);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(I18n.t('mood.title')),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildMoodGrid(),
                if (currentMood != null) ...[
                  const Divider(height: 1),
                  Expanded(
                    child: places.isEmpty
                        ? Center(child: Text(I18n.t('places.notFound')))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: places.length,
                            itemBuilder: (context, i) =>
                                _PlaceCard(place: places[i]),
                          ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildMoodGrid() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.1,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _moods.length,
        itemBuilder: (context, i) {
          final m = _moods[i];
          final selected = m.id == _selected;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _selected = m.id),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: m.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: selected
                      ? Border.all(color: AppTheme.accentOrange, width: 3)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: m.gradient.last.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(m.emoji, style: const TextStyle(fontSize: 32)),
                    const SizedBox(height: 4),
                    Text(
                      I18n.t(m.labelKey),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Mood {
  final String id;
  final String emoji;
  final String labelKey;
  final List<Color> gradient;
  final List<String> keywords;
  final List<String> categories;
  const _Mood({
    required this.id,
    required this.emoji,
    required this.labelKey,
    required this.gradient,
    required this.keywords,
    required this.categories,
  });
}

class _PlaceCard extends StatelessWidget {
  final Place place;
  const _PlaceCard({required this.place});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/place/${place.id}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(place.emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  if (place.category.isNotEmpty)
                    Text(
                      place.category,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.star, size: 14, color: AppTheme.gold),
            const SizedBox(width: 2),
            Text(
              place.rating.toStringAsFixed(1),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
