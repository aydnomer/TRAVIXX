import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _searchController = TextEditingController();

  final List<Map<String, dynamic>> _demoPlaces = [
    {
      'name': 'Harput Kalesi',
      'city': 'Elazığ',
      'emoji': '🏛',
      'km': 6.0,
      'min': 12,
      'category': 'Tarihi',
    },
    {
      'name': 'Hazar Gölü',
      'city': 'Elazığ',
      'emoji': '💧',
      'km': 28.0,
      'min': 35,
      'category': 'Doğa',
    },
    {
      'name': 'Kurşunlu Camii',
      'city': 'Elazığ',
      'emoji': '🕌',
      'km': 14.0,
      'min': 22,
      'category': 'Dini',
    },
    {
      'name': 'Ayasofya',
      'city': 'İstanbul',
      'emoji': '🕌',
      'km': 850.0,
      'min': 600,
      'category': 'Tarihi',
    },
    {
      'name': 'Topkapı Sarayı',
      'city': 'İstanbul',
      'emoji': '🏰',
      'km': 852.0,
      'min': 605,
      'category': 'Müze',
    },
    {
      'name': 'Anıtkabir',
      'city': 'Ankara',
      'emoji': '🏛',
      'km': 490.0,
      'min': 330,
      'category': 'Tarihi',
    },
  ]..sort((a, b) => (a['km'] as double).compareTo(b['km'] as double));

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: isWide ? _buildWebLayout(user) : _buildMobileLayout(user),
      bottomNavigationBar: isWide ? null : _buildBottomNav(),
    );
  }

  Widget _buildMobileLayout(user) {
    return CustomScrollView(
      slivers: [
        _buildHeroSliver(user),
        SliverToBoxAdapter(child: _buildLocationBar()),
        SliverToBoxAdapter(
          child: _buildSectionTitle('Yakınındaki Mekanlar', 'En yakın önce ↑'),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildPlaceCard(_demoPlaces[index], index == 0),
            childCount: _demoPlaces.length,
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
                  'Yakınındaki Mekanlar',
                  'En yakın önce ↑',
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3.5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildPlaceCard(_demoPlaces[index], index == 0),
                    childCount: _demoPlaces.length,
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
      {'icon': Icons.home_outlined, 'label': 'Ana Sayfa'},
      {'icon': Icons.location_city_outlined, 'label': 'Şehirler'},
      {'icon': Icons.qr_code_scanner_outlined, 'label': 'QR Tara'},
      {'icon': Icons.favorite_outline, 'label': 'Favoriler'},
      {'icon': Icons.person_outline, 'label': 'Profil'},
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
            e.value['label'] as String,
            style: TextStyle(
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
          tileColor: isSelected ? const Color(0xFFEFF6FF) : null,
          onTap: () {
            setState(() => _currentIndex = e.key);
            if (e.value['label'] == 'Şehirler') context.push('/cities');
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
                'Merhaba, ${user?.email?.split('@')[0] ?? 'Gezgin'}! 👋',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "Bugün nereyi keşfedelim?",
                style: TextStyle(color: Color(0xFFE0F2FE), fontSize: 13),
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
                        decoration: const InputDecoration(
                          hintText: 'Şehir veya mekan ara...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
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
                  label: const Text(
                    'Şehirleri Keşfet',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
          tooltip: 'Çıkış Yap',
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
            const Expanded(
              child: Text(
                'Çıkış Yap',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Hesabınızdan çıkış yapmak istediğinize emin misiniz?\n\n'
          'Tekrar giriş yapmak için e-posta ve şifrenize ihtiyacınız olacak.',
          style: TextStyle(
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
            child: const Text(
              'İptal',
              style: TextStyle(fontWeight: FontWeight.w600),
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
            child: const Text(
              'Çıkış Yap',
              style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildLocationBar() {
    return Container(
      color: const Color(0xFFEFF6FF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.my_location, color: AppTheme.primary, size: 16),
          const SizedBox(width: 6),
          const Text(
            'Elazığ, Türkiye',
            style: TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const Spacer(),
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

  Widget _buildPlaceCard(Map<String, dynamic> place, bool isNearest) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNearest ? AppTheme.primary : AppTheme.cardBorder,
          width: isNearest ? 1.5 : 0.5,
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
              child: Text(place['emoji'], style: const TextStyle(fontSize: 28)),
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
                      Text(
                        place['name'],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (isNearest) ...[
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
                            style: TextStyle(color: Colors.white, fontSize: 9),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    place['city'],
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _distBadge(
                        Icons.route,
                        '${place['km']} km',
                        const Color(0xFFEFF6FF),
                        AppTheme.primary,
                      ),
                      const SizedBox(width: 6),
                      _distBadge(
                        Icons.access_time,
                        '${place['min']} dk',
                        const Color(0xFFFAEEDA),
                        AppTheme.gold,
                      ),
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
