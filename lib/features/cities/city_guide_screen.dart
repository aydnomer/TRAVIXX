import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/database_service.dart';
import '../../core/utils/weather_service.dart';
import '../community/community_model.dart';
import '../community/community_service.dart';
import '../places/places_screen.dart';
import 'city_model.dart';

/// Şehir rehberi ana ekranı — 3 sekme:
///   1) Mekanlar  — PlacesScreen (embedded mod)
///   2) Rehber    — Hava durumu + ne zaman gidilmeli + pratik bilgi + ulaşım + mutfak
///   3) Notlar    — Community gezi notları (bu şehre ait)
class CityGuideScreen extends StatefulWidget {
  final String cityId;
  final String cityName;

  const CityGuideScreen({
    super.key,
    required this.cityId,
    required this.cityName,
  });

  @override
  State<CityGuideScreen> createState() => _CityGuideScreenState();
}

class _CityGuideScreenState extends State<CityGuideScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  City? _city;
  bool _cityLoading = true;

  WeatherInfo? _weather;
  bool _weatherLoading = false;

  List<CommunityPost> _posts = [];
  bool _postsLoading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadCity();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Veri yükleme ────────────────────────────────────────────────

  Future<void> _loadCity() async {
    try {
      final city = await DatabaseService.getCityById(widget.cityId);
      if (!mounted) return;
      setState(() {
        _city = city ??
            City(
              id: widget.cityId,
              name: widget.cityName,
              nameEn: widget.cityName,
              region: '',
              emoji: '🏙️',
              placeCount: 0,
            );
        _cityLoading = false;
      });
      _loadWeather(_city!);
      _loadPosts(_city!.name);
    } catch (_) {
      if (mounted) setState(() => _cityLoading = false);
    }
  }

  Future<void> _loadWeather(City city) async {
    if (city.latitude == null || city.longitude == null) return;
    setState(() => _weatherLoading = true);
    final w = await WeatherService.currentWeather(
      lat: city.latitude!,
      lng: city.longitude!,
    );
    if (!mounted) return;
    setState(() {
      _weather = w;
      _weatherLoading = false;
    });
  }

  Future<void> _loadPosts(String cityName) async {
    setState(() => _postsLoading = true);
    final all = await CommunityService.getPosts();
    if (!mounted) return;
    final lower = cityName.toLowerCase();
    final filtered = all.where((p) {
      return (p.cityName?.toLowerCase() == lower) ||
          p.title.toLowerCase().contains(lower) ||
          p.description.toLowerCase().contains(lower);
    }).toList();
    setState(() {
      _posts = filtered.isNotEmpty ? filtered : [];
      _postsLoading = false;
    });
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildHeroAppBar()],
        body: Column(
          children: [
            // Tab bar (beyaz şerit)
            Material(
              color: Colors.white,
              elevation: 0,
              child: TabBar(
                controller: _tabCtrl,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.accentOrange,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 12),
                unselectedLabelStyle: const TextStyle(fontSize: 12),
                tabs: [
                  Tab(icon: const Icon(Icons.place_outlined, size: 16), text: I18n.t('cg.tabPlaces')),
                  Tab(icon: const Icon(Icons.info_outline, size: 16), text: I18n.t('cg.tabGuide')),
                  Tab(icon: const Icon(Icons.article_outlined, size: 16), text: I18n.t('cg.tabNotes')),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  // 1 — Mekanlar
                  PlacesScreen(
                    cityId: widget.cityId,
                    cityName: widget.cityName,
                    embedded: true,
                  ),
                  // 2 — Şehir Rehberi
                  _buildGuideTab(),
                  // 3 — Gezi Notları
                  _buildNotesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero AppBar ──────────────────────────────────────────────────

  SliverAppBar _buildHeroAppBar() {
    final city = _city;
    final hasImage = city?.imageUrl != null;

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: _cityLoading
            ? Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryDark, AppTheme.primary],
                  ),
                ),
              )
            : hasImage
                ? _buildPhotoHero(city!)
                : _buildEmojiHero(city ?? _dummyCity()),
      ),
    );
  }

  City _dummyCity() => City(
        id: widget.cityId,
        name: widget.cityName,
        nameEn: '',
        region: '',
        emoji: '🏙️',
        placeCount: 0,
      );

  Widget _buildPhotoHero(City city) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          city.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildEmojiHero(city),
        ),
        // Gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.55),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.7),
              ],
              stops: const [0.0, 0.4, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        // City info
        Positioned(
          bottom: 14,
          left: 16,
          right: 16,
          child: _cityInfoOverlay(city),
        ),
      ],
    );
  }

  Widget _buildEmojiHero(City city) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            bottom: -16,
            child: Opacity(
              opacity: 0.12,
              child: Text(city.emoji,
                  style: const TextStyle(fontSize: 180)),
            ),
          ),
          Positioned(
            bottom: 14,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Text(city.emoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 12),
                Expanded(child: _cityInfoOverlay(city)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cityInfoOverlay(City city) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                city.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                ),
              ),
              if (city.region.isNotEmpty)
                Text(city.region,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
        if (city.placeCount > 0)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.accentOrange.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${city.placeCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(I18n.t('cg.placesUnit'),
                    style:
                        const TextStyle(color: Colors.white, fontSize: 10)),
              ],
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TAB 2 — REHBER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildGuideTab() {
    if (_cityLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final city = _city ?? _dummyCity();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Hava durumu
        if (_weatherLoading || _weather != null) ...[
          _buildWeatherCard(),
          const SizedBox(height: 20),
        ],

        // Pratik Bilgiler
        _sectionTitle('📋 ${I18n.t('cg.practicalInfo')}'),
        const SizedBox(height: 10),
        _buildQuickFacts(city),
        const SizedBox(height: 20),

        // Ne Zaman Gidilmeli
        if (city.region.isNotEmpty) ...[
          _sectionTitle('📅 ${I18n.t('cg.whenToGo')}'),
          const SizedBox(height: 10),
          _buildSeasonalCalendar(city.region),
          const SizedBox(height: 20),
        ],

        // Gezgin İpuçları
        _sectionTitle('💡 ${I18n.t('cg.travelTips')}'),
        const SizedBox(height: 10),
        _buildTipsCard(city.region),
        const SizedBox(height: 20),

        // Ulaşım
        _sectionTitle('🚗 ${I18n.t('cg.transportInfo')}'),
        const SizedBox(height: 10),
        _buildTransportCard(city.region),
        const SizedBox(height: 20),

        // Yeme-İçme
        _sectionTitle('🍽️ ${I18n.t('cg.foodCulture')}'),
        const SizedBox(height: 10),
        _buildFoodCard(city.region),
      ],
    );
  }

  // Hava durumu kartı
  Widget _buildWeatherCard() {
    if (_weatherLoading || _weather == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBAE6FD)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(I18n.t('cg.weatherLoading'),
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
          ],
        ),
      );
    }
    final w = _weather!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDDF2FE), Color(0xFFEFF6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '☀️ ${I18n.t('cg.weatherNow')}',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(w.emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${w.temperatureC.toStringAsFixed(0)}°C',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  Text(
                    I18n.tp('cg.wind', {'speed': w.windKmh.toStringAsFixed(0)}),
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          // 7 günlük tahmin
          if (w.forecast.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            SizedBox(
              height: 64,
              child: Row(
                children: w.forecast.asMap().entries.map((e) {
                  final d = e.value;
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          e.key == 0 ? I18n.t('cg.today') : d.dayLabel(e.key),
                          style: const TextStyle(
                              fontSize: 9,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(d.emoji,
                            style: const TextStyle(fontSize: 18)),
                        Text(
                          '${d.maxC.toStringAsFixed(0)}°',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Pratik bilgiler kartı
  Widget _buildQuickFacts(City city) {
    final facts = [
      ('🗺️', I18n.t('cg.factRegion'),
          city.region.isEmpty ? 'Türkiye' : city.region),
      ('⏰', I18n.t('cg.factTimezone'), 'UTC+3 (TRT)'),
      ('💱', I18n.t('cg.factCurrency'), I18n.t('cg.factCurrencyValue')),
      ('🌡️', I18n.t('cg.factClimate'), _getClimateType(city.region)),
      ('🗣️', I18n.t('cg.factLanguage'), I18n.t('cg.factLanguageValue')),
      ('🔌', I18n.t('cg.factPlug'), I18n.t('cg.factPlugValue')),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: facts.asMap().entries.map((e) {
          final (emoji, label, value) = e.value;
          final isLast = e.key == facts.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Text(emoji,
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Text(label,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text(value,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// Bölge adını (DB değeri) çeviri anahtarı ekine çevirir.
  String _regionKey(String region) {
    switch (region) {
      case 'Marmara':
        return 'marmara';
      case 'Ege':
        return 'aegean';
      case 'Akdeniz':
        return 'med';
      case 'Karadeniz':
        return 'blacksea';
      case 'İç Anadolu':
        return 'central';
      case 'Doğu Anadolu':
        return 'east';
      case 'Güneydoğu Anadolu':
        return 'southeast';
      default:
        return 'default';
    }
  }

  String _getClimateType(String region) =>
      I18n.t('cg.climate.${_regionKey(region)}');

  // Mevsimsel takvim
  Widget _buildSeasonalCalendar(String region) {
    // 0=kaçın, 1=fena değil, 2=iyi, 3=ideal
    final ratings = _getSeasonalRatings(region);
    final months = [
      for (int m = 1; m <= 12; m++) I18n.t('cg.month.$m'),
    ];
    const colors = [
      Color(0xFFEF4444), // 0 kaçın
      Color(0xFFF97316), // 1 fena değil
      Color(0xFFEAB308), // 2 iyi
      Color(0xFF22C55E), // 3 ideal
    ];
    final labels = [for (int i = 0; i < 4; i++) I18n.t('cg.rating.$i')];

    final bestMonths = [
      for (int i = 0; i < 12; i++)
        if (ratings[i] == 3) months[i],
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 6x2 ızgara
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              childAspectRatio: 1.5,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: 12,
            itemBuilder: (_, i) {
              final c = colors[ratings[i]];
              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: c.withValues(alpha: 0.5)),
                ),
                child: Text(
                  months[i],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: c,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // Lejant
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: List.generate(
              4,
              (i) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[i],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(labels[i],
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ),
          if (bestMonths.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                Text(
                  '🌟 ${I18n.t('cg.bestMonths')}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary),
                ),
                Text(
                  bestMonths.join(', '),
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF22C55E),
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<int> _getSeasonalRatings(String region) {
    // Oca, Şub, Mar, Nis, May, Haz, Tem, Ağu, Eyl, Eki, Kas, Ara
    switch (region) {
      case 'Marmara':
        return [1, 1, 2, 3, 3, 2, 2, 2, 3, 3, 2, 1];
      case 'Ege':
        return [1, 1, 2, 3, 3, 2, 1, 1, 3, 3, 2, 1];
      case 'Akdeniz':
        return [2, 2, 2, 3, 3, 2, 0, 0, 3, 3, 2, 2];
      case 'Karadeniz':
        return [1, 1, 1, 2, 2, 3, 3, 3, 2, 1, 1, 1];
      case 'İç Anadolu':
        return [0, 0, 1, 2, 3, 3, 2, 2, 3, 2, 1, 0];
      case 'Doğu Anadolu':
        return [0, 0, 0, 1, 2, 3, 3, 3, 2, 1, 0, 0];
      case 'Güneydoğu Anadolu':
        return [1, 1, 2, 3, 3, 0, 0, 0, 3, 3, 2, 1];
      default:
        return [1, 1, 2, 3, 3, 2, 2, 2, 3, 3, 2, 1];
    }
  }

  // Gezgin ipuçları
  Widget _buildTipsCard(String region) {
    final tips = _getTravelTips(region);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: tips.asMap().entries.map((e) {
          final isLast = e.key == tips.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.accentOrange
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${e.key + 1}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentOrange),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        e.value,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(height: 1, indent: 52, endIndent: 14),
            ],
          );
        }).toList(),
      ),
    );
  }

  List<String> _getTravelTips(String region) {
    final r = _regionKey(region);
    return [for (int i = 1; i <= 5; i++) I18n.t('cg.tip.$r.$i')];
  }

  // Ulaşım bilgisi
  Widget _buildTransportCard(String region) {
    final info = _getTransportInfo(region);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          _transportRow('✈️', I18n.t('cg.transportAir'), info[0]),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          _transportRow('🚌', I18n.t('cg.transportLong'), info[1]),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          _transportRow('🚗', I18n.t('cg.transportCity'), info[2]),
        ],
      ),
    );
  }

  Widget _transportRow(String emoji, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                    height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _getTransportInfo(String region) {
    // [havayolu, uzak mesafe, şehir içi]
    final r = _regionKey(region);
    return [
      I18n.t('cg.tr.$r.air'),
      I18n.t('cg.tr.$r.long'),
      I18n.t('cg.tr.$r.city'),
    ];
  }

  // Yeme-içme kültürü
  Widget _buildFoodCard(String region) {
    final food = _getFoodInfo(region);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            food.$1,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textPrimary, height: 1.6),
          ),
          const SizedBox(height: 12),
          Text(
            I18n.t('cg.mustTry'),
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: food.$2
                .map((dish) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color:
                            AppTheme.accentOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppTheme.accentOrange
                                .withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        dish,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.accentOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  (String, List<String>) _getFoodInfo(String region) {
    switch (region) {
      case 'Marmara':
        return (
          I18n.t('cg.food.marmara'),
          ['Lüfer', 'Midye dolma', 'İskender kebabı', 'Kokoreç', 'Simit', 'Balık ekmek'],
        );
      case 'Ege':
        return (
          I18n.t('cg.food.aegean'),
          ['Zeytinyağlı enginar', 'Çökertme kebabı', 'Boyoz', 'Kumru', 'Levrek', 'İncir tatlısı'],
        );
      case 'Akdeniz':
        return (
          I18n.t('cg.food.med'),
          ['Adana kebabı', 'Tantuni', 'Şiş köfte', 'Portakal tatlısı', 'Kenger turşusu'],
        );
      case 'Karadeniz':
        return (
          I18n.t('cg.food.blacksea'),
          ['Hamsi tavası', 'Kuymak', 'Muhlama', 'Mısır ekmeği', 'Kaburgalı pilav', 'Fındıklı tatlı'],
        );
      case 'İç Anadolu':
        return (
          I18n.t('cg.food.central'),
          ['Etliekmek', 'Kayseri mantısı', 'Pastırma', 'Bici bici', 'Tirit', 'Fırın kebabı'],
        );
      case 'Doğu Anadolu':
        return (
          I18n.t('cg.food.east'),
          ['Van kahvaltısı', 'Otlu peynir', 'Kars gravyeri', 'Malatya kayısısı', 'Kavut', 'Kuzu tandır'],
        );
      case 'Güneydoğu Anadolu':
        return (
          I18n.t('cg.food.southeast'),
          ['Gaziantep baklavası', 'Lahmacun', 'Katmer', 'Beyran çorbası', 'Çiğ köfte', 'Künefe'],
        );
      default:
        return (
          I18n.t('cg.food.default'),
          ['Döner', 'Köfte', 'Güveç', 'Baklava', 'Çay'],
        );
    }
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppTheme.primary,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TAB 3 — GEZİ NOTLARI
  // ═══════════════════════════════════════════════════════════════

  Widget _buildNotesTab() {
    return RefreshIndicator(
      onRefresh: () => _loadPosts(_city?.name ?? widget.cityName),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Not ekle butonu
          _buildAddNoteButton(),
          const SizedBox(height: 16),

          if (_postsLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_posts.isEmpty)
            _buildEmptyNotes()
          else ...[
            Text(
              I18n.tp('cg.notesCount', {'n': '${_posts.length}'}),
              style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            ..._posts.map((p) => _PostCard(post: p)),
          ],
        ],
      ),
    );
  }

  Widget _buildAddNoteButton() {
    return InkWell(
      onTap: _openAddNoteSheet,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.accentOrange, Color(0xFFEAB308)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentOrange.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('✍️', style: TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    I18n.t('cg.shareNote'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                  Text(
                    I18n.t('cg.shareNoteSub'),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyNotes() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          const Text('📝', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            I18n.tp('cg.noNotes', {'city': _city?.name ?? widget.cityName}),
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            I18n.t('cg.beFirst'),
            style:
                const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _openAddNoteSheet() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(I18n.t('cg.loginToShare')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _AddNoteSheet(
        cityName: _city?.name ?? widget.cityName,
        onAdded: () {
          Navigator.pop(ctx);
          _loadPosts(_city?.name ?? widget.cityName);
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Gezi notu kartı
// ═══════════════════════════════════════════════════════════════

class _PostCard extends StatelessWidget {
  final CommunityPost post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final daysAgo = DateTime.now().difference(post.createdAt).inDays;
    final timeText = daysAgo == 0
        ? I18n.t('cg.today')
        : daysAgo == 1
            ? I18n.t('cg.yesterday')
            : I18n.tp('cg.daysAgo', {'n': '$daysAgo'});

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kapak fotoğraf (varsa)
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(13)),
              child: Image.network(
                post.imageUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Açıklama
                Text(
                  post.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                // Yazar ve tarih
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppTheme.accentOrange,
                      child: Text(
                        post.userName.isNotEmpty
                            ? post.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.userName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                          Text(
                            timeText,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (post.cityName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primary
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          post.cityName!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Gezi notu ekle / alt sayfa
// ═══════════════════════════════════════════════════════════════

class _AddNoteSheet extends StatefulWidget {
  final String cityName;
  final VoidCallback onAdded;
  const _AddNoteSheet({required this.cityName, required this.onAdded});

  @override
  State<_AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<_AddNoteSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(I18n.t('cg.titleDescRequired')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    final ok = await CommunityService.addPost(
      title: title,
      description: desc,
      cityName: widget.cityName,
    );
    if (!mounted) return;
    if (ok) {
      widget.onAdded();
    } else {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(I18n.t('cg.shareFailed')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
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
            Text(
              I18n.tp('cg.sheetTitle', {'city': widget.cityName}),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            // Başlık
            TextField(
              controller: _titleCtrl,
              maxLength: 80,
              decoration: InputDecoration(
                labelText: I18n.t('cg.titleLabel'),
                hintText: I18n.t('cg.titleHint'),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Açıklama
            TextField(
              controller: _descCtrl,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: I18n.t('cg.noteLabel'),
                hintText: I18n.t('cg.noteHint'),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, size: 16),
                label: Text(I18n.t('cg.share')),
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
}
