import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/daily_challenge.dart';
import '../../core/utils/database_service.dart';
import '../../core/utils/gps_service.dart';
import '../../core/utils/weather_service.dart';
import '../cities/city_model.dart';
import '../collections/collection_card.dart';
import '../collections/collection_model.dart';
import '../collections/collection_service.dart';
import '../notifications/notification_bell.dart';
import '../places/place_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _PlaceWithDistance {
  final Place place;
  final double? km;
  final int? minutes;
  const _PlaceWithDistance(
      {required this.place, required this.km, required this.minutes});
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  List<_PlaceWithDistance> _places = [];
  bool _loading = true;
  Position? _userPos;

  List<City> _cities = [];
  List<PlaceCollection> _collections = const [];
  WeatherInfo? _weather;

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
    CollectionService.getCollections().then((list) {
      if (mounted) setState(() => _collections = list);
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
      int? min;
      if (pos != null && p.latitude != null && p.longitude != null) {
        km = GpsService.distanceKm(
            pos.latitude, pos.longitude, p.latitude!, p.longitude!);
        min = GpsService.estimateMinutes(km);
      }
      return _PlaceWithDistance(place: p, km: km, minutes: min);
    }).toList();

    if (pos != null) {
      list.sort((a, b) {
        if (a.km == null && b.km == null) return 0;
        if (a.km == null) return 1;
        if (b.km == null) return -1;
        return a.km!.compareTo(b.km!);
      });
    }

    setState(() {
      _userPos = pos;
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

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: isWide ? _buildWebLayout(user) : _buildMobileLayout(user),
      bottomNavigationBar: isWide ? null : _buildBottomNav(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/ai-chat'),
        backgroundColor: AppTheme.accentOrange,
        foregroundColor: Colors.white,
        icon: const Text('🤖', style: TextStyle(fontSize: 18)),
        label: Text(
          I18n.t('ai.openChat'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        elevation: 4,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MOBILE: Netflix şeritler
  // ═══════════════════════════════════════════════════════════════

  Widget _buildMobileLayout(user) {
    return CustomScrollView(
      slivers: [
        _buildCompactHero(user),
        SliverToBoxAdapter(child: _buildNearbyStrip()),
        SliverToBoxAdapter(child: _buildFeaturesHorizontal()),
        SliverToBoxAdapter(child: _buildCitiesStrip()),
        if (_collections.isNotEmpty)
          SliverToBoxAdapter(child: _buildCollectionsStrip()),
        SliverToBoxAdapter(child: _buildDailyChallenge()),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // WEB: Yan menü + şeritler
  // ═══════════════════════════════════════════════════════════════

  Widget _buildWebLayout(user) {
    return Row(
      children: [
        _buildWebSidebar(),
        Expanded(
          child: CustomScrollView(
            slivers: [
              _buildCompactHero(user),
              SliverToBoxAdapter(child: _buildNearbyStrip()),
              SliverToBoxAdapter(child: _buildFeaturesHorizontal()),
              SliverToBoxAdapter(child: _buildCitiesStrip()),
              if (_collections.isNotEmpty)
                SliverToBoxAdapter(child: _buildCollectionsStrip()),
              SliverToBoxAdapter(child: _buildDailyChallenge()),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // KOMPAKT HERO (160 px)
  // ═══════════════════════════════════════════════════════════════

  SliverAppBar _buildCompactHero(user) {
    final userName =
        user?.email?.split('@')[0] ?? I18n.t('profile.travelerName');
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';
    final gpsActive = _userPos != null;

    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: AppTheme.primary,
      actions: [
        const NotificationBell(),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          tooltip: I18n.t('logout.tooltip'),
          onPressed: _confirmLogout,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary, Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Selamlama satırı
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.accentOrange, Color(0xFFEAB308)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              I18n.tp('home.greeting', {'name': userName}),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                Icon(
                                  gpsActive
                                      ? Icons.my_location
                                      : Icons.location_disabled,
                                  color: gpsActive
                                      ? Colors.greenAccent
                                      : Colors.white38,
                                  size: 11,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  gpsActive ? 'Konum aktif' : 'Konum kapalı',
                                  style: TextStyle(
                                    color: gpsActive
                                        ? Colors.greenAccent
                                        : Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (_weather != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            children: [
                              Text(_weather!.emoji,
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 4),
                              Text(
                                '${_weather!.temperatureC.toStringAsFixed(0)}°',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Arama çubuğu — tıklanınca /search açılır
                  GestureDetector(
                    onTap: () => context.push('/search'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search,
                              color: AppTheme.textSecondary, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            I18n.t('home.searchHint'),
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 14),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.accentOrange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '81 il',
                              style: TextStyle(
                                color: AppTheme.accentOrange,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ŞERİT 1 — Yakın / Popüler Mekanlar
  // ═══════════════════════════════════════════════════════════════

  Widget _buildNearbyStrip() {
    final title = _userPos != null ? '📍 Yakınındakiler' : '⭐ Popüler Mekanlar';
    final sub =
        _userPos != null ? 'GPS\'e göre sıralı' : 'En yüksek puanlılar';

    return _StripWrapper(
      title: title,
      subtitle: sub,
      onSeeAll: () => context.push('/cities'),
      child: SizedBox(
        height: 195,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _places.isEmpty
                ? const Center(
                    child: Text('Mekan bulunamadı',
                        style: TextStyle(color: AppTheme.textSecondary)))
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: _places.length.clamp(0, 12),
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) => _PlaceCard(
                      pwd: _places[i],
                      onTap: () =>
                          context.push('/place/${_places[i].place.id}'),
                    ),
                  ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ŞERİT 2 — Hızlı Erişim
  // ═══════════════════════════════════════════════════════════════

  Widget _buildFeaturesHorizontal() {
    const features = [
      {'emoji': '🗺️', 'label': 'Rota\nSihirbazı', 'route': '/trip-wizard', 'color': 0xFF1A2744},
      {'emoji': '▶️', 'label': 'Video\nRehberler', 'route': '/videos', 'color': 0xFFDC2626},
      {'emoji': '📍', 'label': 'Gizli\nMekanlar', 'route': '/community', 'color': 0xFFF97316},
      {'emoji': '🏡', 'label': 'Konaklama', 'route': '/accommodation', 'color': 0xFF16A34A},
      {'emoji': '🗺', 'label': 'Harita', 'route': '/map', 'color': 0xFF7C3AED},
      {'emoji': '🏆', 'label': 'En İyiler', 'route': '/top-rated', 'color': 0xFFB45309},
      {'emoji': '📓', 'label': 'Günlük', 'route': '/diaries', 'color': 0xFF0369A1},
      {'emoji': '🏙️', 'label': 'Şehirler', 'route': '/cities', 'color': 0xFF1A2744},
    ];

    return _StripWrapper(
      title: '⚡ Hızlı Erişim',
      subtitle: 'Tüm özellikler',
      child: SizedBox(
        height: 88,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          itemCount: features.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final f = features[i];
            final color = Color(f['color'] as int);
            return GestureDetector(
              onTap: () => context.push(f['route'] as String),
              child: Container(
                width: 76,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(f['emoji'] as String,
                        style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 5),
                    Text(
                      f['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ŞERİT 3 — Popüler Şehirler
  // ═══════════════════════════════════════════════════════════════

  Widget _buildCitiesStrip() {
    return _StripWrapper(
      title: '🏙️ Popüler Şehirler',
      subtitle: '81 il keşfetmeye hazır',
      onSeeAll: () => context.push('/cities'),
      child: SizedBox(
        height: 118,
        child: _cities.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: _cities.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final c = _cities[i];
                  return GestureDetector(
                    onTap: () =>
                        context.push('/city/${c.id}', extra: c.name),
                    child: Container(
                      width: 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.cardBorder),
                        color: Colors.white,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          c.imageUrl != null
                              ? Image.network(
                                  c.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _cityFallback(c),
                                )
                              : _cityFallback(c),
                          // Alt gradient + isim
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(6, 20, 6, 7),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.72),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              child: Text(
                                c.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _cityFallback(City c) {
    return Container(
      color: AppTheme.primary.withValues(alpha: 0.08),
      child: Center(
          child: Text(c.emoji, style: const TextStyle(fontSize: 30))),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ŞERİT 4 — Tematik Koleksiyonlar (mevcut)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildCollectionsStrip() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      I18n.t('collections.title'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    Text(
                      I18n.t('collections.subtitle'),
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.push('/collections'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(50, 30),
                ),
                child: Text(
                  I18n.t('collections.seeAll'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.accentOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: _collections.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) =>
                CollectionCard(collection: _collections[i]),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // GÜNÜN GÖREVİ (alt kısım)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDailyChallenge() {
    final c = DailyChallenge.today();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/cities'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.accentOrange, Color(0xFFEAB308)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentOrange.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(c.emoji, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      I18n.t('challenge.title'),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      I18n.t(c.titleKey),
                      style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      I18n.t(c.descKey),
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // WEB SIDEBAR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildWebSidebar() {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flight, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              const Text(
                'Travixx',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "Türkiye'yi Keşfet",
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 32),
          ..._buildSidebarItems(),
        ],
      ),
    );
  }

  List<Widget> _buildSidebarItems() {
    final items = [
      {'icon': Icons.home_outlined, 'key': 'sidebar.home', 'route': '/home'},
      {'icon': Icons.location_city_outlined, 'key': 'sidebar.cities', 'route': '/cities'},
      {'icon': Icons.map_outlined, 'key': 'map.menuLabel', 'route': '/map'},
      {'icon': Icons.restaurant_outlined, 'key': 'restaurants.menuLabel', 'route': '/restaurants'},
      {'icon': Icons.mood, 'key': 'mood.title', 'route': '/mood'},
      {'icon': Icons.compare_arrows, 'key': 'compare.menuLabel', 'route': '/compare'},
      {'icon': Icons.qr_code_scanner_outlined, 'key': 'sidebar.qr', 'route': '/qr-scan'},
      {'icon': Icons.favorite_outline, 'key': 'sidebar.favorites', 'route': '/favorites'},
      {'icon': Icons.person_outline, 'key': 'sidebar.profile', 'route': '/profile'},
    ];
    return items.asMap().entries.map((e) {
      final isSelected = e.key == _currentIndex;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          leading: Icon(
            e.value['icon'] as IconData,
            color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
            size: 22,
          ),
          title: Text(
            I18n.t(e.value['key'] as String),
            style: TextStyle(
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
          tileColor: isSelected ? const Color(0xFFEFF6FF) : null,
          onTap: () {
            setState(() => _currentIndex = e.key);
            final route = e.value['route'] as String;
            if (route != '/home') context.push(route);
          },
        ),
      );
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // BOTTOM NAV
  // ═══════════════════════════════════════════════════════════════

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (i) {
        setState(() => _currentIndex = i);
        if (i == 1) context.push('/cities');
        if (i == 2) context.push('/qr-scan');
        if (i == 3) context.push('/favorites');
        if (i == 4) context.push('/profile');
      },
      selectedItemColor: AppTheme.primary,
      unselectedItemColor: AppTheme.textSecondary,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined), label: 'Ana Sayfa'),
        BottomNavigationBarItem(
            icon: Icon(Icons.location_city_outlined), label: 'Şehirler'),
        BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_outlined), label: 'QR Tara'),
        BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline), label: 'Favoriler'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), label: 'Profil'),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ÇIKIŞ DİALOGU
  // ═══════════════════════════════════════════════════════════════

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout,
                  color: AppTheme.accentOrange, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                I18n.t('logout.title'),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary),
              ),
            ),
          ],
        ),
        content: Text(
          I18n.t('logout.confirm'),
          style: const TextStyle(
              fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(I18n.t('common.cancel'),
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 0,
            ),
            child: Text(I18n.t('logout.title'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) context.go('/');
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// YARDIMCİ WİDGET'LAR
// ═══════════════════════════════════════════════════════════════

/// Şerit başlığı + "Tümü →" butonu + içerik
class _StripWrapper extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onSeeAll;
  final Widget child;

  const _StripWrapper({
    required this.title,
    required this.subtitle,
    this.onSeeAll,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(50, 28),
                  ),
                  child: const Text(
                    'Tümü →',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.accentOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}

/// Yatay mekan kartı (foto arka plan + gradient)
class _PlaceCard extends StatelessWidget {
  final _PlaceWithDistance pwd;
  final VoidCallback onTap;

  const _PlaceCard({required this.pwd, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = pwd.place;
    final hasImage = p.images.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder),
          color: Colors.white,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fotoğraf veya emoji arka plan
            hasImage
                ? Image.network(
                    p.images[0],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _emojiBg(p.emoji),
                  )
                : _emojiBg(p.emoji),
            // Alt gradient
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (pwd.km != null) ...[
                          const Icon(Icons.near_me,
                              color: Colors.white70, size: 10),
                          const SizedBox(width: 3),
                          Text(
                            '${pwd.km!.toStringAsFixed(1)} km',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 10),
                          ),
                        ] else ...[
                          const Icon(Icons.star,
                              color: Colors.amber, size: 11),
                          const SizedBox(width: 2),
                          Text(
                            p.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 10),
                          ),
                        ],
                        if (p.isFree) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Ücretsiz',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 9),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emojiBg(String emoji) {
    return Container(
      color: AppTheme.primary.withValues(alpha: 0.07),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 40))),
    );
  }
}
