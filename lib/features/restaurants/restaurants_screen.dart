import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/gps_service.dart';
import '../../core/utils/overpass_service.dart';

/// Yakındaki yemek mekanları için bağımsız ekran.
/// GPS izniyle kullanıcı konumundan 2km içindeki restoran/kafe/bar vb.
class RestaurantsScreen extends StatefulWidget {
  const RestaurantsScreen({super.key});

  @override
  State<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen> {
  List<NearbyVenue> _venues = const [];
  bool _loading = true;
  Position? _userPos;
  String _selectedType = 'all';
  int _radiusKm = 2;

  static const _types = [
    {'value': 'all', 'label': 'Tümü', 'emoji': '🍽️'},
    {'value': 'restaurant', 'label': 'Restoran', 'emoji': '🍽️'},
    {'value': 'cafe', 'label': 'Kafe', 'emoji': '☕'},
    {'value': 'fast_food', 'label': 'Fast Food', 'emoji': '🍔'},
    {'value': 'bar', 'label': 'Bar', 'emoji': '🍺'},
    {'value': 'bakery', 'label': 'Fırın', 'emoji': '🥐'},
    {'value': 'ice_cream', 'label': 'Dondurma', 'emoji': '🍦'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final pos = await GpsService.getCurrentPosition();
    if (pos == null) {
      if (mounted) {
        setState(() {
          _userPos = null;
          _venues = const [];
          _loading = false;
        });
      }
      return;
    }
    final venues = await OverpassService.nearbyFood(
      lat: pos.latitude,
      lng: pos.longitude,
      radiusMeters: _radiusKm * 1000,
      limit: 50,
    );
    if (!mounted) return;
    setState(() {
      _userPos = pos;
      _venues = venues;
      _loading = false;
    });
  }

  List<NearbyVenue> get _filtered {
    if (_selectedType == 'all') return _venues;
    return _venues.where((v) => v.amenity == _selectedType).toList();
  }

  Future<void> _openMap(NearbyVenue v) async {
    final uri = Uri.parse(v.mapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(I18n.t('restaurants.title')),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              GpsService.clearCache();
              _load();
            },
            tooltip: I18n.t('common.retry'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _userPos == null
              ? _buildGpsRequired()
              : Column(
                  children: [
                    _buildFilterChips(),
                    _buildHeaderInfo(),
                    Expanded(
                      child: _filtered.isEmpty
                          ? Center(
                              child: Text(I18n.t('food.empty')),
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: _filtered.length,
                                itemBuilder: (context, i) {
                                  return _VenueTile(
                                    venue: _filtered[i],
                                    onTap: () => _openMap(_filtered[i]),
                                  );
                                },
                              ),
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
        itemCount: _types.length,
        itemBuilder: (context, i) {
          final t = _types[i];
          final selected = t['value'] == _selectedType;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t['emoji']!, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(t['label']!),
                ],
              ),
              selected: selected,
              onSelected: (_) =>
                  setState(() => _selectedType = t['value']!),
              backgroundColor: Colors.white,
              selectedColor: AppTheme.accentOrange.withValues(alpha: 0.15),
              checkmarkColor: AppTheme.accentOrange,
              labelStyle: TextStyle(
                color: selected ? AppTheme.accentOrange : AppTheme.textPrimary,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: selected
                      ? AppTheme.accentOrange
                      : AppTheme.cardBorder,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFEFF6FF),
      child: Row(
        children: [
          const Icon(Icons.my_location, size: 14, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            '${_filtered.length} ${I18n.t('restaurants.foundIn')} ${_radiusKm}km',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Yarıçap değiştirici
          DropdownButton<int>(
            value: _radiusKm,
            underline: const SizedBox.shrink(),
            isDense: true,
            items: const [
              DropdownMenuItem(value: 1, child: Text('1 km')),
              DropdownMenuItem(value: 2, child: Text('2 km')),
              DropdownMenuItem(value: 3, child: Text('3 km')),
              DropdownMenuItem(value: 5, child: Text('5 km')),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() => _radiusKm = v);
                _load();
              }
            },
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_disabled,
                size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              I18n.t('restaurants.gpsRequired'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              I18n.t('restaurants.gpsDesc'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                GpsService.clearCache();
                _load();
              },
              icon: const Icon(Icons.refresh),
              label: Text(I18n.t('common.retry')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VenueTile extends StatelessWidget {
  final NearbyVenue venue;
  final VoidCallback onTap;
  const _VenueTile({required this.venue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(venue.emoji, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accentOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            venue.typeLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.accentOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (venue.cuisine != null) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              venue.cuisine!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    venue.distanceText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const Icon(Icons.directions,
                      size: 18, color: AppTheme.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
