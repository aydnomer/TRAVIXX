import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/database_service.dart';
import '../../core/utils/overpass_service.dart';
import '../../core/utils/share_service.dart';
import '../../core/utils/weather_service.dart';
import '../../core/utils/wikipedia_service.dart';
import '../gamification/badge_service.dart';
import '../reviews/review_service.dart';
import 'place_model.dart';

class PlaceDetailScreen extends StatefulWidget {
  final String placeId;
  const PlaceDetailScreen({super.key, required this.placeId});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  Place? _place;
  bool _loading = true;
  bool _isFavorite = false;
  bool _favLoading = false;

  // Foto galerisi için PageController
  final PageController _galleryCtrl = PageController();
  int _galleryIdx = 0;

  // Hava durumu (lat/lng varsa fetch edilir)
  WeatherInfo? _weather;
  bool _weatherLoading = false;

  // Yorumlar
  List<Review> _reviews = const [];
  Review? _myReview;
  bool _reviewsLoading = true;

  // Yakındaki yemek mekanları
  List<NearbyVenue> _nearbyFood = const [];
  bool _foodLoading = false;
  bool _foodAttempted = false;

  // Wikipedia fallback foto (DB'de yoksa)
  String? _wikiPhoto;

  @override
  void dispose() {
    _galleryCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadPlace();
  }

  Future<void> _loadPlace() async {
    try {
      final p = await DatabaseService.getPlaceById(widget.placeId);
      if (!mounted) return;
      setState(() {
        _place = p;
        _loading = false;
      });
      if (p != null) {
        _checkFavorite();
        _loadWeather(p);
        _loadReviews(p.id);
        _loadNearbyFood(p);
        _loadWikiPhotoIfNeeded(p);
        // Ziyaret kaydı (gamification için, 24 saat deduplikasyon var)
        BadgeService.recordVisit(p.id);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // DB'de foto yoksa Wikipedia'dan çekmeyi dene
  Future<void> _loadWikiPhotoIfNeeded(Place p) async {
    if (p.images.isNotEmpty) return; // zaten foto var
    final url = await WikipediaService.fetchThumbnail(
      name: p.name,
      nameEn: p.nameEn.isNotEmpty ? p.nameEn : null,
    );
    if (!mounted) return;
    if (url != null) {
      setState(() => _wikiPhoto = url);
      // Best-effort: Supabase'e geri yaz (sessizce, hata olursa atla)
      Supabase.instance.client
          .from('places')
          .update({'images': [url]})
          .eq('id', p.id)
          .then((_) {}, onError: (_) {});
    }
  }

  Future<void> _loadNearbyFood(Place p) async {
    if (p.latitude == null || p.longitude == null) return;
    setState(() {
      _foodLoading = true;
      _foodAttempted = true;
    });
    final venues = await OverpassService.nearbyFood(
      lat: p.latitude!,
      lng: p.longitude!,
      radiusMeters: 1500,
      limit: 12,
    );
    if (!mounted) return;
    setState(() {
      _nearbyFood = venues;
      _foodLoading = false;
    });
  }

  Future<void> _loadReviews(String placeId) async {
    final results = await Future.wait([
      ReviewService.getReviews(placeId),
      ReviewService.getMyReview(placeId),
    ]);
    if (!mounted) return;
    setState(() {
      _reviews = results[0] as List<Review>;
      _myReview = results[1] as Review?;
      _reviewsLoading = false;
    });
  }

  Future<void> _openReviewSheet(Place p) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showSnack(I18n.t('review.loginRequired'), isError: true);
      return;
    }
    final updated = await showModalBottomSheet<Review>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ReviewSheet(
        placeId: p.id,
        existing: _myReview,
      ),
    );

    if (updated != null && mounted) {
      _showSnack(I18n.t('review.saved'), isError: false);
      // Yorumları yenile
      _loadReviews(p.id);
    }
  }

  Future<void> _deleteMyReview(Place p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: Text(I18n.t('review.delete')),
        content: Text(I18n.t('review.deleteConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(I18n.t('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(I18n.t('review.delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await ReviewService.delete(p.id);
    if (!mounted) return;
    if (ok) {
      _showSnack(I18n.t('review.deleted'), isError: false);
      _loadReviews(p.id);
    }
  }

  Future<void> _loadWeather(Place p) async {
    if (p.latitude == null || p.longitude == null) return;
    setState(() => _weatherLoading = true);
    final w = await WeatherService.currentWeather(
      lat: p.latitude!,
      lng: p.longitude!,
    );
    if (!mounted) return;
    setState(() {
      _weather = w;
      _weatherLoading = false;
    });
  }

  Future<void> _checkFavorite() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _place == null) return;
    try {
      final res = await Supabase.instance.client
          .from('favorites')
          .select()
          .eq('user_id', user.id)
          .eq('place_id', _place!.id)
          .maybeSingle();
      if (mounted) setState(() => _isFavorite = res != null);
    } catch (_) {
      // Sessizce yut — favori kontrolü kritik değil
    }
  }

  Future<void> _toggleFavorite() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showSnack(I18n.t('place.favLoginRequired'), isError: true);
      return;
    }
    if (_place == null || _favLoading) return;
    setState(() => _favLoading = true);
    try {
      if (_isFavorite) {
        await Supabase.instance.client
            .from('favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('place_id', _place!.id);
        if (mounted) {
          setState(() => _isFavorite = false);
          _showSnack(I18n.t('place.favRemoved'), isError: false);
        }
      } else {
        await Supabase.instance.client.from('favorites').insert({
          'user_id': user.id,
          'place_id': _place!.id,
        });
        if (mounted) {
          setState(() => _isFavorite = true);
          _showSnack(I18n.t('place.favAdded'), isError: false);
        }
      }
    } catch (e) {
      if (mounted) _showSnack('${I18n.t('auth.genericError')}: $e', isError: true);
    } finally {
      if (mounted) setState(() => _favLoading = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_place == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(I18n.t('place.notFound'),
                  style: const TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        ),
      );
    }
    final p = _place!;
    final hasMap = p.latitude != null && p.longitude != null;
    final hasContact = (p.website?.isNotEmpty ?? false) ||
        (p.phone?.isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          _buildHeroAppBar(p),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBadgeRow(p),
                  if (_weather != null || _weatherLoading) ...[
                    const SizedBox(height: 12),
                    _buildWeatherStrip(),
                  ],
                  const SizedBox(height: 20),
                  _buildTitleSection(p),
                  const SizedBox(height: 24),
                  _sectionTitle(I18n.t('place.description')),
                  const SizedBox(height: 10),
                  _buildDescriptionCard(p),
                  // Açılış saatleri
                  if ((p.openingHours?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 20),
                    _infoCard(
                      icon: Icons.access_time,
                      title: I18n.t('place.hours'),
                      content: p.openingHours!,
                    ),
                  ],
                  // Giriş ücreti (ücretsiz değilse ve detay varsa)
                  if (!p.isFree && (p.admissionFee?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 12),
                    _infoCard(
                      icon: Icons.confirmation_number_outlined,
                      title: I18n.t('place.admission'),
                      content: p.admissionFee!,
                      accentColor: AppTheme.gold,
                    ),
                  ],
                  // Adres
                  if ((p.address?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 12),
                    _infoCard(
                      icon: Icons.location_on_outlined,
                      title: I18n.t('place.address'),
                      content: p.address!,
                      trailing: IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () async {
                          await Clipboard.setData(
                              ClipboardData(text: p.address!));
                          if (mounted) {
                            _showSnack(I18n.t('place.copyAddress'),
                                isError: false);
                          }
                        },
                      ),
                    ),
                  ],
                  // İletişim
                  if (hasContact) ...[
                    const SizedBox(height: 20),
                    _sectionTitle(I18n.t('place.contact')),
                    const SizedBox(height: 10),
                    if (p.website?.isNotEmpty ?? false)
                      _linkRow(
                        icon: Icons.language,
                        label: I18n.t('place.website'),
                        value: p.website!,
                        onTap: () => _openUrl(p.website!),
                      ),
                    if ((p.website?.isNotEmpty ?? false) &&
                        (p.phone?.isNotEmpty ?? false))
                      const SizedBox(height: 8),
                    if (p.phone?.isNotEmpty ?? false)
                      _linkRow(
                        icon: Icons.phone_outlined,
                        label: I18n.t('place.phone'),
                        value: p.phone!,
                        onTap: () => _openUrl('tel:${p.phone}'),
                      ),
                  ],
                  if (hasMap) ...[
                    const SizedBox(height: 24),
                    _sectionTitle(I18n.t('place.location')),
                    const SizedBox(height: 10),
                    _buildMap(p),
                    const SizedBox(height: 10),
                    _buildDirectionsButton(p),
                  ],
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  if (_foodAttempted) ...[
                    const SizedBox(height: 28),
                    _sectionTitle(I18n.t('food.title')),
                    const SizedBox(height: 10),
                    _buildNearbyFoodSection(),
                  ],
                  const SizedBox(height: 28),
                  _sectionTitle(I18n.t('review.title')),
                  const SizedBox(height: 10),
                  _buildReviewsSection(p),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Paylaşım alt sayfası
  void _openShareSheet(Place p) {
    final url = 'https://aydnomer.github.io/TRAVIXX/#/place/${p.id}';
    final text = '${p.emoji} ${p.name} — Travixx ile keşfet!';

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
            Text(
              I18n.t('share.title'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              p.name,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            // Sosyal medya satırı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _shareBtn(
                  icon: '💬',
                  label: I18n.t('share.whatsapp'),
                  color: const Color(0xFF25D366),
                  onTap: () {
                    Navigator.pop(ctx);
                    ShareService.shareToWhatsApp('$text $url');
                  },
                ),
                _shareBtn(
                  icon: '🐦',
                  label: I18n.t('share.twitter'),
                  color: const Color(0xFF1DA1F2),
                  onTap: () {
                    Navigator.pop(ctx);
                    ShareService.shareToTwitter(text, url: url);
                  },
                ),
                _shareBtn(
                  icon: '👍',
                  label: I18n.t('share.facebook'),
                  color: const Color(0xFF1877F2),
                  onTap: () {
                    Navigator.pop(ctx);
                    ShareService.shareToFacebook(url);
                  },
                ),
                _shareBtn(
                  icon: '📧',
                  label: I18n.t('share.email'),
                  color: AppTheme.textSecondary,
                  onTap: () {
                    Navigator.pop(ctx);
                    ShareService.shareViaEmail(
                      subject: text,
                      body: '$text\n\n$url',
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Link kopyala
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final ok = await ShareService.copyToClipboard(url);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (ok && mounted) {
                    _showSnack(I18n.t('share.linkCopied'), isError: false);
                  }
                },
                icon: const Icon(Icons.link, size: 18),
                label: Text(I18n.t('share.copyLink')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
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

  Widget _shareBtn({
    required String icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Material(
          color: color.withValues(alpha: 0.1),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 26)),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  // URL launcher — web sitesi, telefon, harita
  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Sessizce geç
    }
  }

  /// Place'in görsellerini + Wikipedia fallback'i birlikte döner
  List<String> _effectiveImages(Place p) {
    if (p.images.isNotEmpty) return p.images;
    if (_wikiPhoto != null) return [_wikiPhoto!];
    return const [];
  }

  Widget _buildHeroAppBar(Place p) {
    final images = _effectiveImages(p);
    final hasImages = images.isNotEmpty;
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppTheme.primary,
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
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share_outlined,
                color: Colors.white, size: 20),
          ),
          onPressed: () => _openShareSheet(p),
          tooltip: I18n.t('share.button'),
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.redAccent : Colors.white,
              size: 20,
            ),
          ),
          onPressed: _favLoading ? null : _toggleFavorite,
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: hasImages
            ? _buildGallery(p, images)
            : _buildEmojiHero(p),
      ),
    );
  }

  // Galeri: PageView ile birden fazla foto, alt dot indicator
  Widget _buildGallery(Place p, List<String> images) {
    return Stack(
      children: [
        PageView.builder(
          controller: _galleryCtrl,
          itemCount: images.length,
          onPageChanged: (i) => setState(() => _galleryIdx = i),
          itemBuilder: (context, i) {
            return Image.network(
              images[i],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildEmojiHero(p),
            );
          },
        ),
        // Karanlık alt gradient (geri/favori ikonları okunaklı olsun)
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                  ],
                  stops: const [0.0, 0.2, 0.7, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),
        // Dot indicator (birden fazla foto varsa)
        if (images.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) {
                final active = i == _galleryIdx;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildEmojiHero(Place p) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryDark,
            AppTheme.primary,
            AppTheme.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -10,
            right: -10,
            child: Opacity(
              opacity: 0.18,
              child: Text(p.emoji, style: const TextStyle(fontSize: 220)),
            ),
          ),
          Center(
            child: Text(p.emoji, style: const TextStyle(fontSize: 110)),
          ),
        ],
      ),
    );
  }

  // Bilgi kartı (saat, ücret, adres ortak kartı)
  Widget _infoCard({
    required IconData icon,
    required String title,
    required String content,
    Color accentColor = AppTheme.primary,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  // Tıklanabilir link satırı (telefon, web)
  Widget _linkRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new,
                size: 16, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  // Hava durumu şeridi — mekanın koordinatına göre anlık hava
  Widget _buildWeatherStrip() {
    if (_weatherLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('...', style: TextStyle(fontSize: 13)),
          ],
        ),
      );
    }
    final w = _weather;
    if (w == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDDF2FE), Color(0xFFEFF6FF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Row(
        children: [
          Text(w.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${w.temperatureC.toStringAsFixed(0)}°C',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              Text(
                I18n.t('place.weatherNow'),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.air, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${w.windKmh.toStringAsFixed(0)} km/h',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Yakındaki yemek mekanları bölümü
  Widget _buildNearbyFoodSection() {
    if (_foodLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              I18n.t('food.loading'),
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    if (_nearbyFood.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Center(
          child: Text(
            I18n.t('food.empty'),
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _nearbyFood.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final v = _nearbyFood[i];
          return _FoodCard(venue: v, onTap: () => _openUrl(v.mapsUrl));
        },
      ),
    );
  }

  // Yorumlar bölümü
  Widget _buildReviewsSection(Place p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Yorum yaz butonu
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.accentOrange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.accentOrange.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.rate_review_outlined,
                  color: AppTheme.accentOrange),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _myReview == null
                      ? I18n.t('review.writeReview')
                      : I18n.t('review.editReview'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _openReviewSheet(p),
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _myReview == null
                      ? I18n.t('review.submit')
                      : I18n.t('common.save'),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              if (_myReview != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteMyReview(p),
                  tooltip: I18n.t('review.delete'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Yorum listesi
        if (_reviewsLoading)
          const Center(child: CircularProgressIndicator())
        else if (_reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Center(
              child: Text(
                I18n.t('review.noReviews'),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          )
        else
          Column(
            children: [
              // Yorum sayısı
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${_reviews.length} ${I18n.t('review.countLabel')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ..._reviews.map((r) => _ReviewCard(review: r)),
            ],
          ),
      ],
    );
  }

  // Google Maps'e yol tarifi butonu
  Widget _buildDirectionsButton(Place p) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          final url =
              'https://www.google.com/maps/dir/?api=1&destination=${p.latitude},${p.longitude}';
          _openUrl(url);
        },
        icon: const Icon(Icons.directions, size: 18),
        label: Text(
          I18n.t('place.getDirections'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF22C55E),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildBadgeRow(Place p) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (p.category.isNotEmpty)
          _badge(p.category, AppTheme.accentOrange, isLight: true),
        _ratingBadge(p.rating),
        _badge(
          p.isFree ? I18n.t('place.free') : I18n.t('place.paid'),
          p.isFree ? Colors.green : Colors.deepOrange,
          isLight: true,
        ),
        if (p.isFeatured)
          _badge('⭐ ${I18n.t('place.featured')}', AppTheme.gold, isLight: true),
      ],
    );
  }

  Widget _buildTitleSection(Place p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          p.name,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
            height: 1.2,
          ),
        ),
        if (p.nameEn.isNotEmpty && p.nameEn != p.name) ...[
          const SizedBox(height: 4),
          Text(
            p.nameEn,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDescriptionCard(Place p) {
    final desc = p.description.isNotEmpty
        ? p.description
        : I18n.t('place.descPlaceholder');
    return Container(
      width: double.infinity,
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
            desc,
            style: const TextStyle(
              fontSize: 14,
              height: 1.7,
              color: AppTheme.textPrimary,
            ),
          ),
          if (p.descriptionEn.isNotEmpty &&
              p.descriptionEn != p.description) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Text(
              p.descriptionEn,
              style: const TextStyle(
                fontSize: 13,
                height: 1.6,
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMap(Place p) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(p.latitude!, p.longitude!),
                initialZoom: 13,
                interactionOptions: const InteractionOptions(
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
                  markers: [
                    Marker(
                      point: LatLng(p.latitude!, p.longitude!),
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.accentOrange,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.place,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '© OpenStreetMap',
                  style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              _showSnack(I18n.t('place.qrSoon'), isError: false);
            },
            icon: const Icon(Icons.qr_code_scanner, size: 18),
            label: Text(I18n.t('place.qrScan')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _favLoading ? null : _toggleFavorite,
            icon: _favLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                  ),
            label: Text(_isFavorite ? I18n.t('place.isFavorite') : I18n.t('place.addFavorite')),
            style: OutlinedButton.styleFrom(
              foregroundColor: _isFavorite ? Colors.red : AppTheme.primary,
              side: BorderSide(
                color: _isFavorite ? Colors.red : AppTheme.primary,
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.primary,
      ),
    );
  }

  Widget _badge(String label, Color color, {bool isLight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isLight ? color.withValues(alpha: 0.15) : color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isLight ? color : Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _ratingBadge(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAB308).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: Color(0xFFEAB308)),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFB45309),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bir yorum kartı (kullanıcı adı + yıldızlar + tarih + metin)
/// Yakındaki yemek mekanı kartı (yatay scroll içinde)
class _FoodCard extends StatelessWidget {
  final NearbyVenue venue;
  final VoidCallback onTap;
  const _FoodCard({required this.venue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      venue.emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    venue.distanceText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                venue.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                  height: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                venue.cuisine ?? venue.typeLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final daysAgo = DateTime.now().difference(review.createdAt).inDays;
    final timeText = daysAgo == 0
        ? 'Bugün'
        : daysAgo == 1
            ? 'Dün'
            : '$daysAgo gün önce';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.accentOrange,
                child: Text(
                  review.displayName.isNotEmpty
                      ? review.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.displayName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
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
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating ? Icons.star : Icons.star_border,
                    size: 14,
                    color: const Color(0xFFEAB308),
                  );
                }),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Alt sayfa: yorum yaz/düzenle modali
class _ReviewSheet extends StatefulWidget {
  final String placeId;
  final Review? existing;
  const _ReviewSheet({required this.placeId, this.existing});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  late int _rating;
  late TextEditingController _commentCtrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.existing?.rating ?? 5;
    _commentCtrl =
        TextEditingController(text: widget.existing?.comment ?? '');
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(I18n.t('review.ratingRequired'))),
      );
      return;
    }
    setState(() => _submitting = true);
    final review = await ReviewService.upsert(
      placeId: widget.placeId,
      rating: _rating,
      comment: _commentCtrl.text,
    );
    if (!mounted) return;
    Navigator.pop(context, review);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
              widget.existing == null
                  ? I18n.t('review.writeReview')
                  : I18n.t('review.editReview'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            // Yıldız seçici
            Text(
              I18n.t('review.yourRating'),
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) {
                return IconButton(
                  onPressed: () => setState(() => _rating = i + 1),
                  icon: Icon(
                    i < _rating ? Icons.star : Icons.star_border,
                    size: 36,
                    color: const Color(0xFFEAB308),
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                );
              }),
            ),
            const SizedBox(height: 12),
            Text(
              I18n.t('review.yourComment'),
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: I18n.t('review.commentHint'),
                hintStyle: const TextStyle(fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
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
                label: Text(I18n.t('review.submit')),
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
