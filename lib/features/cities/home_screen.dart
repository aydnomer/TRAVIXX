import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/utils/database_service.dart';
import '../../core/utils/gps_service.dart';
import '../../core/utils/weather_service.dart';
import '../../shared/layout/bottom_nav.dart';
import '../../shared/layout/cards.dart';
import '../../shared/layout/city_quick_cards.dart';
import '../../shared/layout/mobile_header.dart';
import '../../shared/layout/nav_destinations.dart';
import '../../shared/layout/nav_rail.dart';
import '../../shared/layout/profile_drawer.dart';
import '../../shared/layout/topbar.dart';
import '../cities/city_model.dart';
import '../places/place_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _PlaceWithDistance {
  final Place place;
  final double? km;
  const _PlaceWithDistance({required this.place, required this.km});
}

class _HomeScreenState extends State<HomeScreen> {
  List<_PlaceWithDistance> _places = [];
  bool _loading = true;
  List<City> _cities = [];
  WeatherInfo? _weather;
  String _category = 'Tümü';

  static const _categories = [
    'Tümü', 'Müzeler', 'Kaleler', 'Doğa', 'Restoranlar', 'Camiler',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final posFuture = GpsService.getCurrentPosition();
    final placesFuture = DatabaseService.getAllPlaces();

    DatabaseService.getCities().then((list) {
      if (mounted) setState(() => _cities = list.take(15).toList());
    });

    final pos = await posFuture;
    List<Place> raw;
    try {
      raw = await placesFuture;
    } catch (_) {
      raw = const [];
    }
    if (!mounted) return;

    final list = raw.map((p) {
      double? km;
      if (pos != null && p.latitude != null && p.longitude != null) {
        km = GpsService.distanceKm(
            pos.latitude, pos.longitude, p.latitude!, p.longitude!);
      }
      return _PlaceWithDistance(place: p, km: km);
    }).toList();

    if (pos != null) {
      list.sort((a, b) {
        if (a.km == null) return 1;
        if (b.km == null) return -1;
        return a.km!.compareTo(b.km!);
      });
    }

    setState(() {
      _places = list.take(20).toList();
      _loading = false;
    });

    if (pos != null) {
      WeatherService.currentWeather(lat: pos.latitude, lng: pos.longitude)
          .then((w) {
        if (mounted && w != null) setState(() => _weather = w);
      });
    }
  }

  List<_PlaceWithDistance> get _filtered {
    if (_category == 'Tümü') return _places;
    final key = {
      'Müzeler': 'müze',
      'Kaleler': 'kale',
      'Doğa': 'doğa',
      'Restoranlar': 'restoran',
      'Camiler': 'cami',
    }[_category];
    if (key == null) return _places;
    return _places
        .where((p) => p.place.category.toLowerCase().contains(key) ||
            (key == 'doğa' &&
                (p.place.category.toLowerCase().contains('park') ||
                    p.place.category.toLowerCase().contains('şelale') ||
                    p.place.category.toLowerCase().contains('mağara'))))
        .toList();
  }

  String get _avatar =>
      avatarInitials(Supabase.instance.client.auth.currentUser?.email);
  String? get _temp =>
      _weather != null ? '${_weather!.temperatureC.round()}°' : null;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isWide = w >= 768;
    return Scaffold(
      backgroundColor: DT.bg,
      body: isWide ? _webLayout(w) : _mobileLayout(),
      bottomNavigationBar:
          isWide ? null : const BottomNav(currentRoute: '/home'),
    );
  }

  // ── WEB ──────────────────────────────────────────────────────
  Widget _webLayout(double width) {
    final cols = width >= 1280 ? 4 : (width >= 1024 ? 3 : 2);
    final showRail = width >= 1024;
    return Row(
      children: [
        if (showRail)
          NavRail(
            currentRoute: '/home',
            avatarText: _avatar,
            onProfileTap: () => showProfileDrawer(context),
          ),
        Expanded(
          child: Column(
            children: [
              Topbar(
                title: 'Ana Sayfa',
                temperature: _temp,
                avatarText: _avatar,
                onProfileTap: () => showProfileDrawer(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            DT.s32, DT.s24, DT.s32, DT.s48),
                        child: _content(cols: cols, cityW: 180, cityH: 120),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── MOBİL ────────────────────────────────────────────────────
  Widget _mobileLayout() {
    return Column(
      children: [
        MobileHeader(
          locationName: 'Türkiye',
          avatarText: _avatar,
          onProfileTap: () => context.push('/profile'),
          onLocationTap: () => context.push('/cities'),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: DT.s32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: DT.s16),
                _mobileSearch(),
                const SizedBox(height: DT.s16),
                _categoryChips(),
                const SizedBox(height: DT.s24),
                _content(cols: 1, cityW: 140, cityH: 90, mobile: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _mobileSearch() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: DT.s16),
        child: InkWell(
          onTap: () => context.push('/search'),
          borderRadius: DT.brPill,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: DT.s12),
            decoration: BoxDecoration(
              color: DT.surface,
              borderRadius: DT.brPill,
              border: DT.boxBorder,
            ),
            child: const Row(
              children: [
                Icon(Icons.search, size: 18, color: DT.textMuted),
                SizedBox(width: DT.s8),
                Text('Şehir veya mekan ara...', style: DT.muted12),
              ],
            ),
          ),
        ),
      );

  Widget _categoryChips() => SizedBox(
        height: 32,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: DT.s16),
          itemCount: _categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: DT.s8),
          itemBuilder: (_, i) {
            final c = _categories[i];
            final active = c == _category;
            return GestureDetector(
              onTap: () => setState(() => _category = c),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? DT.primary : DT.surface,
                  borderRadius: DT.brPill,
                  border: Border.all(
                      color: active ? DT.primary : DT.border, width: 1),
                ),
                child: Text(c,
                    style: TextStyle(
                        fontSize: 13,
                        color: active ? Colors.white : DT.textSecondary,
                        fontWeight: DT.wMedium)),
              ),
            );
          },
        ),
      );

  // ── Ortak içerik ─────────────────────────────────────────────
  Widget _content(
      {required int cols,
      required double cityW,
      required double cityH,
      bool mobile = false}) {
    final places = _filtered;
    final hPad = mobile ? DT.s16 : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Yakındakiler
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: _sectionRow('Yakınındakiler', 'Tümünü gör →',
              () => context.push('/search')),
        ),
        const SizedBox(height: DT.s12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(DT.s32),
            child: Center(child: CircularProgressIndicator(color: DT.primary)),
          )
        else if (places.isEmpty)
          Padding(
            padding: EdgeInsets.all(DT.s16).copyWith(left: hPad + 16),
            child: const Text('Bu kategoride mekan bulunamadı.',
                style: DT.muted12),
          )
        else if (mobile)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DT.s16),
            child: Column(
              children: places
                  .take(8)
                  .map((p) => PlaceListRow(
                        place: p.place,
                        distanceKm: p.km,
                        onTap: () => context.push('/place/${p.place.id}'),
                      ))
                  .toList(),
            ),
          )
        else
          GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: DT.s12,
            crossAxisSpacing: DT.s12,
            childAspectRatio: 1.0,
            children: places
                .take(cols * 2)
                .map((p) => PlaceCard(
                      place: p.place,
                      distanceKm: p.km,
                      onTap: () => context.push('/place/${p.place.id}'),
                    ))
                .toList(),
          ),
        const SizedBox(height: DT.s32),

        // Ne yapmak istiyorsun? (web 2x2 / mobil tek sütun)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Text('Ne yapmak istiyorsun?', style: DT.t16),
        ),
        const SizedBox(height: DT.s12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: GridView.count(
            crossAxisCount: mobile ? 1 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: DT.s12,
            crossAxisSpacing: DT.s12,
            childAspectRatio: mobile ? 5.5 : 4.0,
            children: [
              QuickActionCard(
                icon: Icons.route_outlined,
                color: DT.primary,
                title: 'Rota Oluştur',
                subtitle: 'Sana özel gezi rotası planla',
                onTap: () => context.push('/trip-wizard'),
              ),
              QuickActionCard(
                icon: Icons.map_outlined,
                color: DT.catNature,
                title: 'Haritada Gez',
                subtitle: 'Tüm mekanları haritada gör',
                onTap: () => context.push('/map'),
              ),
              QuickActionCard(
                icon: Icons.location_city_outlined,
                color: DT.catCastle,
                title: 'Şehir Keşfet',
                subtitle: '81 ili keşfetmeye başla',
                onTap: () => context.push('/cities'),
              ),
              QuickActionCard(
                icon: Icons.auto_awesome_outlined,
                color: DT.catMosque,
                title: 'Rehber Bul',
                subtitle: 'AI gezi asistanına sor',
                onTap: () => context.push('/ai-chat'),
              ),
            ],
          ),
        ),
        const SizedBox(height: DT.s32),

        // Popüler Şehirler
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: _sectionRow(
              'Popüler Şehirler', 'Tümü →', () => context.push('/cities')),
        ),
        const SizedBox(height: DT.s12),
        SizedBox(
          height: cityH,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: hPad),
            itemCount: _cities.length,
            separatorBuilder: (_, __) => const SizedBox(width: DT.s12),
            itemBuilder: (_, i) => CityCard(
              city: _cities[i],
              width: cityW,
              height: cityH,
              onTap: () => context.push('/city/${_cities[i].id}',
                  extra: _cities[i].name),
            ),
          ),
        ),

        // Mobil: Rota Oluştur tam genişlik buton
        if (mobile) ...[
          const SizedBox(height: DT.s24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DT.s16),
            child: InkWell(
              onTap: () => context.push('/trip-wizard'),
              borderRadius: DT.brCard,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: DT.s16),
                decoration: BoxDecoration(
                    color: DT.primary, borderRadius: DT.brCard),
                child: const Row(
                  children: [
                    Icon(Icons.route_outlined, size: 20, color: Colors.white),
                    SizedBox(width: DT.s12),
                    Expanded(
                      child: Text('Rota Oluştur',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: DT.wMedium)),
                    ),
                    Icon(Icons.chevron_right, size: 20, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionRow(String title, String action, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: DT.sectionMuted),
        InkWell(
          onTap: onTap,
          child: Text(action, style: DT.primaryLink),
        ),
      ],
    );
  }
}
