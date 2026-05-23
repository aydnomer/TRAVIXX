import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../places/place_model.dart';
import 'collection_model.dart';
import 'collection_service.dart';

/// Bir koleksiyonun detay ekranı: kapak + içindeki mekanlar.
class CollectionDetailScreen extends StatefulWidget {
  final String collectionId;
  const CollectionDetailScreen({super.key, required this.collectionId});

  @override
  State<CollectionDetailScreen> createState() =>
      _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  PlaceCollection? _collection;
  List<Place> _places = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      CollectionService.getCollection(widget.collectionId),
      CollectionService.getPlacesInCollection(widget.collectionId),
    ]);
    if (!mounted) return;
    setState(() {
      _collection = results[0] as PlaceCollection?;
      _places = results[1] as List<Place>;
      _loading = false;
    });
  }

  Color _hex(String h) {
    final clean = h.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final c = _collection;
    if (c == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(child: Text(I18n.t('collections.notFound'))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: _hex(c.coverGradientEnd),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back,
                    color: Colors.white, size: 20),
              ),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _hex(c.coverGradientStart),
                      _hex(c.coverGradientEnd),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Opacity(
                        opacity: 0.18,
                        child: Text(c.emoji,
                            style: const TextStyle(fontSize: 220)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            c.emoji,
                            style: const TextStyle(fontSize: 36),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_places.length} ${I18n.t('collections.places')}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (c.description.isNotEmpty) ...[
                    Text(
                      c.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (_places.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Text(
                          I18n.t('collections.emptyPlaces'),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._places.map((p) => _PlaceListItem(place: p)),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceListItem extends StatelessWidget {
  final Place place;
  const _PlaceListItem({required this.place});

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
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(place.emoji, style: const TextStyle(fontSize: 28)),
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
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  if (place.description.isNotEmpty)
                    Text(
                      place.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (place.category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accentOrange
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            place.category,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.accentOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      const Icon(Icons.star,
                          size: 14, color: AppTheme.gold),
                      const SizedBox(width: 2),
                      Text(
                        place.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
