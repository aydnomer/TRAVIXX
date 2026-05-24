import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/database_service.dart';
import '../places/place_model.dart';

/// Türkiye genelinde en yüksek puanlı mekanlar.
class TopRatedScreen extends StatefulWidget {
  const TopRatedScreen({super.key});

  @override
  State<TopRatedScreen> createState() => _TopRatedScreenState();
}

class _TopRatedScreenState extends State<TopRatedScreen> {
  List<Place> _places = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await DatabaseService.getTopRated(limit: 50, minRating: 4.5);
    if (!mounted) return;
    setState(() {
      _places = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(I18n.t('topRated.title')),
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
          : _places.isEmpty
              ? Center(child: Text(I18n.t('places.notFound')))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _places.length,
                    itemBuilder: (context, i) =>
                        _TopRatedTile(place: _places[i], rank: i + 1),
                  ),
                ),
    );
  }
}

class _TopRatedTile extends StatelessWidget {
  final Place place;
  final int rank;
  const _TopRatedTile({required this.place, required this.rank});

  Color _rankColor() {
    if (rank == 1) return const Color(0xFFEAB308); // altın
    if (rank == 2) return const Color(0xFF94A3B8); // gümüş
    if (rank == 3) return const Color(0xFFCD7F32); // bronz
    return AppTheme.primary;
  }

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
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _rankColor().withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: _rankColor(), width: 2),
              ),
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _rankColor(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(place.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
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
                    overflow: TextOverflow.ellipsis,
                  ),
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
            const Icon(Icons.star, size: 18, color: Color(0xFFEAB308)),
            const SizedBox(width: 3),
            Text(
              place.rating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
