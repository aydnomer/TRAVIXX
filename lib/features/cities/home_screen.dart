import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/database_service.dart';
import '../../core/utils/gps_service.dart';
import '../collections/collection_card.dart';
import '../collections/collection_model.dart';
import '../collections/collection_service.dart';
import '../places/place_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// Bir mekanı kullanıcıya olan mesafesiyle birlikte tutan basit sınıf.
class _PlaceWithDistance {
  final Place place;
  final double? km;
  final int? minutes;
  const _PlaceWithDistance(
      {required this.place, required this.km, required this.minutes});
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Gerçek Supabase verisi + GPS mesafe sıralaması
  List<_PlaceWithDistance> _places = [];
  bool _loading = true;
  Position? _userPos;
  String _gpsStatus = '';

  // Tematik koleksiyonlar
  List<PlaceCollection> _collections = const [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Önce GPS izni iste (paralel)
    final posFuture = GpsService.getCurrentPosition();
    // Aynı anda mekanları çek
    final placesFuture = DatabaseService.getAllPlaces();
    // Koleksiyonları da paralel çek (hata olursa boş kalır)
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

    // Mesafe hesapla ve sırala
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

    // GPS varsa mesafeye göre sırala, yoksa rating'e göre
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
      _places = list.take(20).toList(); // ilk 20
      _gpsStatus = pos != null ? I18n.t('home.gpsActive') : I18n.t('home.gpsOff');
      _loading = false;
    });
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

  Widget _buildMobileLayout(user) {
    return CustomScrollView(
      slivers: [
        _buildHeroSliver(user),
        SliverToBoxAdapter(child: _buildLocationBar()),
        if (_collections.isNotEmpty)
          SliverToBoxAdapter(child: _buildCollectionsStrip()),
        SliverToBoxAdapter(
          child: _buildSectionTitle(
            _userPos != null ? I18n.t('home.nearby') : I18n.t('home.popular'),
            _userPos != null
                ? I18n.t('home.nearbySub')
                : I18n.t('home.popularSub'),
          ),
        ),
        if (_loading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_places.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('Mekan bulunamadı')),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  _buildPlaceCard(_places[index], index == 0),
              childCount: _places.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _buildWebLayout(user) {
    return Row(
      children: [
        _buildWebSidebar(),
        Expanded(
          child: CustomScrollView(
            slivers: [
              _buildHeroSliver(user),
              SliverToBoxAdapter(child: _buildLocationBar()),
              SliverToBoxAdapter(
                child: _buildSectionTitle(
                  _userPos != null
                      ? I18n.t('home.nearby')
                      : I18n.t('home.popular'),
                  _userPos != null
                      ? I18n.t('home.nearbySub')
                      : I18n.t('home.popularSub'),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_places.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text(I18n.t('home.notFound'))),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3.5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildPlaceCard(_places[index], index == 0),
                      childCount: _places.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ],
    );
  }

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
      {
        'icon': Icons.location_city_outlined,
        'key': 'sidebar.cities',
        'route': '/cities'
      },
      {
        'icon': Icons.map_outlined,
        'key': 'map.menuLabel',
        'route': '/map'
      },
      {
        'icon': Icons.qr_code_scanner_outlined,
        'key': 'sidebar.qr',
        'route': '/qr-scan'
      },
      {
        'icon': Icons.favorite_outline,
        'key': 'sidebar.favorites',
        'route': '/favorites'
      },
      {
        'icon': Icons.person_outline,
        'key': 'sidebar.profile',
        'route': '/profile'
      },
    ];
    return items.asMap().entries.map((e) {
      final isSelected = e.key == _currentIndex;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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

  SliverAppBar _buildHeroSliver(user) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: const Color(0xFF60A5FA),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF60A5FA), Color(0xFF93C5FD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                I18n.tp('home.greeting', {
                  'name': user?.email?.split('@')[0] ??
                      I18n.t('profile.travelerName')
                }),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                I18n.t('home.subtitle'),
                style: const TextStyle(color: Color(0xFFE0F2FE), fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFF3B82F6)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onTap: () {
                          // Doğrudan dokunduğunda da arama ekranını aç
                          if (_searchController.text.isEmpty) {
                            context.push('/search');
                          }
                        },
                        onSubmitted: (q) {
                          final query = q.trim();
                          if (query.isEmpty) {
                            context.push('/search');
                          } else {
                            context.push('/search?q=${Uri.encodeComponent(query)}');
                          }
                        },
                        decoration: InputDecoration(
                          hintText: I18n.t('home.searchHint'),
                          border: InputBorder.none,
                          hintStyle: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/cities'),
                  icon: const Icon(Icons.explore, size: 18),
                  label: Text(
                    I18n.t('home.exploreBtn'),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          tooltip: I18n.t('logout.tooltip'),
          onPressed: _confirmLogout,
        ),
      ],
    );
  }

  // Çıkış onay dialog'u — profesyonel görünüm
  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.logout,
                color: AppTheme.accentOrange,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                I18n.t('logout.title'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          I18n.t('logout.confirm'),
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              I18n.t('common.cancel'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 0,
            ),
            child: Text(
              I18n.t('logout.title'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) context.go('/');
    }
  }

  // Tematik koleksiyon şeridi (yatay scroll)
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    Text(
                      I18n.t('collections.subtitle'),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
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
            itemBuilder: (context, i) {
              return CollectionCard(collection: _collections[i]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLocationBar() {
    final gpsActive = _userPos != null;
    return Container(
      color: const Color(0xFFEFF6FF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            gpsActive ? Icons.my_location : Icons.location_disabled,
            color: gpsActive ? AppTheme.primary : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _gpsStatus,
              style: TextStyle(
                color: gpsActive ? AppTheme.primary : AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!gpsActive)
            TextButton(
              onPressed: () {
                GpsService.clearCache();
                setState(() => _loading = true);
                _loadData();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(50, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Tekrar dene',
                style: TextStyle(fontSize: 11),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'GPS aktif',
                style: TextStyle(color: Colors.green, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String hint) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            hint,
            style: const TextStyle(fontSize: 11, color: AppTheme.primaryLight),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(_PlaceWithDistance pwd, bool isNearest) {
    final p = pwd.place;
    final hasDistance = pwd.km != null;
    return InkWell(
      onTap: () => context.push('/place/${p.id}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isNearest && hasDistance
                ? AppTheme.primary
                : AppTheme.cardBorder,
            width: isNearest && hasDistance ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
              child: Center(
                child: Text(p.emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (isNearest && hasDistance) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'En Yakın',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 9),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      p.category.isNotEmpty ? p.category : 'Mekan',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (hasDistance) ...[
                          _distBadge(
                            Icons.route,
                            '${pwd.km!.toStringAsFixed(1)} km',
                            const Color(0xFFEFF6FF),
                            AppTheme.primary,
                          ),
                          const SizedBox(width: 6),
                          _distBadge(
                            Icons.access_time,
                            '${pwd.minutes} dk',
                            const Color(0xFFFEF9C3),
                            const Color(0xFFB45309),
                          ),
                        ] else ...[
                          _distBadge(
                            Icons.star,
                            p.rating.toStringAsFixed(1),
                            const Color(0xFFFEF9C3),
                            const Color(0xFFB45309),
                          ),
                        ],
                        const SizedBox(width: 6),
                        _distBadge(
                          Icons.qr_code_scanner,
                          'QR',
                          AppTheme.primary,
                          Colors.white,
                        ),
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

  Widget _distBadge(IconData icon, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: fg,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

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
          icon: Icon(Icons.home_outlined),
          label: 'Ana Sayfa',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.location_city_outlined),
          label: 'Şehirler',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_scanner_outlined),
          label: 'QR Tara',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_outline),
          label: 'Favoriler',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profil',
        ),
      ],
    );
  }
}
