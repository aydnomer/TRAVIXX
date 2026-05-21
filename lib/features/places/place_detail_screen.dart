import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/database_service.dart';
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
      if (p != null) _checkFavorite();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
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
                  const SizedBox(height: 20),
                  _buildTitleSection(p),
                  const SizedBox(height: 24),
                  _sectionTitle(I18n.t('place.description')),
                  const SizedBox(height: 10),
                  _buildDescriptionCard(p),
                  if (hasMap) ...[
                    const SizedBox(height: 24),
                    _sectionTitle(I18n.t('place.location')),
                    const SizedBox(height: 10),
                    _buildMap(p),
                  ],
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroAppBar(Place p) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppTheme.primary,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
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
              color: Colors.black.withValues(alpha: 0.25),
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
        background: Container(
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
              // Sağ üstte yarı saydam büyük emoji
              Positioned(
                top: -10,
                right: -10,
                child: Opacity(
                  opacity: 0.18,
                  child: Text(
                    p.emoji,
                    style: const TextStyle(fontSize: 220),
                  ),
                ),
              ),
              // Ortada güzel duran emoji
              Center(
                child: Text(
                  p.emoji,
                  style: const TextStyle(fontSize: 110),
                ),
              ),
            ],
          ),
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
