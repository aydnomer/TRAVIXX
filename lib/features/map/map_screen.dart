import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/database_service.dart';
import '../places/place_model.dart';

/// Türkiye'nin tüm mekanlarını interaktif harita üzerinde gösterir.
/// Marker'a tıklayınca alt sayfada mini kart açılır.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();
  List<Place> _places = const [];
  bool _loading = true;
  String _selectedCategory = 'Tümü';

  static const _categories = [
    'Tümü',
    'Tarihi',
    'Müze',
    'Doğa',
    'Kültür',
    'Dini',
  ];

  // Türkiye merkez koordinat
  static const _turkeyCenter = LatLng(39.0, 35.0);
  static const _initialZoom = 6.0;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaces() async {
    try {
      final all = await DatabaseService.getAllPlaces();
      // Sadece lat/lng'si olanları al
      final withCoords = all
          .where((p) => p.latitude != null && p.longitude != null)
          .toList();
      if (!mounted) return;
      setState(() {
        _places = withCoords;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Place> get _filteredPlaces {
    if (_selectedCategory == 'Tümü') return _places;
    return _places.where((p) => p.category == _selectedCategory).toList();
  }

  /// Kategoriye göre marker rengi
  Color _markerColor(String category) {
    switch (category) {
      case 'Tarihi':
        return const Color(0xFFEA580C); // turuncu
      case 'Müze':
        return const Color(0xFF7C3AED); // mor
      case 'Doğa':
        return const Color(0xFF16A34A); // yeşil
      case 'Kültür':
        return const Color(0xFFDB2777); // pembe
      case 'Dini':
        return const Color(0xFF0891B2); // turkuaz
      case 'Manzara':
        return const Color(0xFFCA8A04); // altın
      default:
        return AppTheme.primary;
    }
  }

  void _showPlaceSheet(Place p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _markerColor(p.category).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(p.emoji, style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      if (p.nameEn.isNotEmpty)
                        Text(
                          p.nameEn,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: [
                _badge(p.category, _markerColor(p.category)),
                _badge('⭐ ${p.rating.toStringAsFixed(1)}',
                    const Color(0xFFEAB308)),
                if (p.isFree) _badge(I18n.t('place.free'), Colors.green),
              ],
            ),
            if (p.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                p.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/place/${p.id}');
                },
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Detaylar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(I18n.t('map.title')),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            tooltip: I18n.t('map.resetZoom'),
            onPressed: () => _mapController.move(_turkeyCenter, _initialZoom),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterChips(),
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: const MapOptions(
                          initialCenter: _turkeyCenter,
                          initialZoom: _initialZoom,
                          minZoom: 5,
                          maxZoom: 18,
                          interactionOptions: InteractionOptions(
                            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.travixx.app',
                          ),
                          MarkerLayer(
                            markers: _filteredPlaces.map((p) {
                              final color = _markerColor(p.category);
                              return Marker(
                                point:
                                    LatLng(p.latitude!, p.longitude!),
                                width: 38,
                                height: 38,
                                child: GestureDetector(
                                  onTap: () => _showPlaceSheet(p),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.25),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        p.emoji,
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      // Mekan sayısı banner'ı
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.place,
                                  size: 14, color: AppTheme.accentOrange),
                              const SizedBox(width: 4),
                              Text(
                                '${_filteredPlaces.length} ${I18n.t('home.popular').toLowerCase()}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // OpenStreetMap attribution
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '© OpenStreetMap',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _categories.length,
        itemBuilder: (context, i) {
          final c = _categories[i];
          final selected = c == _selectedCategory;
          final color = c == 'Tümü' ? AppTheme.primary : _markerColor(c);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(c),
              selected: selected,
              onSelected: (_) => setState(() => _selectedCategory = c),
              backgroundColor: Colors.white,
              selectedColor: color.withValues(alpha: 0.15),
              checkmarkColor: color,
              labelStyle: TextStyle(
                color: selected ? color : AppTheme.textPrimary,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: selected ? color : AppTheme.cardBorder,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
