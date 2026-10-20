import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/categories.dart';
import '../../core/i18n/i18n.dart';
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
    'Tümü', 'Plajlar', 'Tarihi', 'Müzeler', 'Doğa', 'Kültür', 'Kaleler',
    'Camiler', 'Manzara',
  ];

  /// Çip id'si (switch'te kullanılır) → görünen ad anahtarı.
  static const _categoryKeys = {
    'Tümü': 'ah.home.chip.all',
    'Plajlar': 'ah.home.chip.beaches',
    'Tarihi': 'ah.home.chip.historic',
    'Müzeler': 'ah.home.chip.museums',
    'Doğa': 'ah.home.chip.nature',
    'Kültür': 'ah.home.chip.culture',
    'Kaleler': 'ah.home.chip.castles',
    'Camiler': 'ah.home.chip.mosques',
    'Manzara': 'ah.home.chip.scenic',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    DatabaseService.getCities().then((list) {
      if (mounted) setState(() => _cities = list.take(15).toList());
    });

    final pos = await GpsService.getCurrentPosition();
    // Kategori çipleri bu listeyi süzer; yeterince geniş tutulur.
    List<Place> raw;
    try {
      raw = pos != null
          ? await DatabaseService.getNearbyPlaces(
              pos.latitude, pos.longitude, limit: 200)
          : await DatabaseService.getPopularPlaces(limit: 200);
    } catch (_) {
      try {
        raw = await DatabaseService.getPopularPlaces(limit: 200);
      } catch (_) {
        raw = const [];
      }
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
      _places = list;
      _loading = false;
    });

    if (pos != null) {
      WeatherService.currentWeather(lat: pos.latitude, lng: pos.longitude)
          .then((w) {
        if (mounted && w != null) setState(() => _weather = w);
      });
    }
  }

  List<_PlaceWithDistance> get _filtered => _matching.take(20).toList();

  List<_PlaceWithDistance> get _matching {
    if (_category == 'Tümü') return _places;
    bool Function(Place) test;
    switch (_category) {
      case 'Plajlar':
        test = (p) => p.category == Categories.beach;
      case 'Tarihi':
        test = (p) => p.category == Categories.historic;
      case 'Müzeler':
        test = (p) => p.category == Categories.museum;
      case 'Doğa':
        test = (p) => p.category == Categories.nature;
      case 'Kültür':
        test = (p) => p.category == Categories.culture;
      case 'Manzara':
        test = (p) => p.category == Categories.scenic;
      // Kale ve cami ayrı kategori değil; ada göre bulunur.
      case 'Kaleler':
        test = (p) => Categories.containsAny(p.name, const ['kale', 'hisar']);
      case 'Camiler':
        test = (p) =>
            Categories.containsAny(p.name, const ['cami', 'mescit']) ||
            (p.category == Categories.religious &&
                Categories.containsAny(p.subcategory ?? '', const ['cami']));
      default:
        return _places;
    }
    return _places.where((p) => test(p.place)).toList();
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
                title: I18n.t('ah.nav.home'),
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
          locationName: I18n.t('ah.home.country'),
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
            child: Row(
              children: [
                const Icon(Icons.search, size: 18, color: DT.textMuted),
                const SizedBox(width: DT.s8),
                Text(I18n.t('ah.common.searchHint'), style: DT.muted12),
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
                child: Text(I18n.t(_categoryKeys[c] ?? c),
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
          child: _sectionRow(I18n.t('ah.home.nearby'), I18n.t('ah.home.seeAll'),
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
            child: Text(I18n.t('ah.home.emptyCategory'),
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
          child: Text(I18n.t('ah.home.whatToDo'), style: DT.t16),
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
                title: I18n.t('ah.home.createRoute'),
                subtitle: I18n.t('ah.home.createRouteSub'),
                onTap: () => context.push('/trip-wizard'),
              ),
              QuickActionCard(
                icon: Icons.map_outlined,
                color: DT.catNature,
                title: I18n.t('ah.home.mapTitle'),
                subtitle: I18n.t('ah.home.mapSub'),
                onTap: () => context.push('/map'),
              ),
              QuickActionCard(
                icon: Icons.location_city_outlined,
                color: DT.catCastle,
                title: I18n.t('ah.home.citiesTitle'),
                subtitle: I18n.t('ah.home.citiesSub'),
                onTap: () => context.push('/cities'),
              ),
              QuickActionCard(
                icon: Icons.auto_awesome_outlined,
                color: DT.catMosque,
                title: I18n.t('ah.home.guideTitle'),
                subtitle: I18n.t('ah.home.guideSub'),
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
              I18n.t('ah.home.popularCities'), I18n.t('ah.home.allArrow'), () => context.push('/cities')),
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
                child: Row(
                  children: [
                    const Icon(Icons.route_outlined, size: 20, color: Colors.white),
                    const SizedBox(width: DT.s12),
                    Expanded(
                      child: Text(I18n.t('ah.home.createRoute'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: DT.wMedium)),
                    ),
                    const Icon(Icons.chevron_right, size: 20, color: Colors.white),
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
