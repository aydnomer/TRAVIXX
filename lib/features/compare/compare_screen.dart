import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/database_service.dart';
import '../places/place_model.dart';
import 'compare_service.dart';

/// Sepete eklenen mekanları (en fazla 4) yan-yana tablo halinde karşılaştırır.
class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  List<Place> _places = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ids = CompareService.basket.value;
    if (ids.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    // Sepetteki ID'ler için place verilerini sırayla çek
    final all = await DatabaseService.getAllPlaces();
    if (!mounted) return;
    final byId = {for (final p in all) p.id: p};
    final places = ids
        .map((id) => byId[id])
        .whereType<Place>()
        .toList();
    setState(() {
      _places = places;
      _loading = false;
    });
  }

  Future<void> _remove(Place p) async {
    await CompareService.remove(p.id);
    _load();
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(I18n.t('compare.clearTitle')),
        content: Text(I18n.t('compare.clearConfirm')),
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
            child: Text(I18n.t('compare.clear')),
          ),
        ],
      ),
    );
    if (ok == true) {
      await CompareService.clear();
      if (mounted) _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(I18n.t('compare.title')),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        actions: [
          if (_places.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: I18n.t('compare.clear'),
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _places.isEmpty
              ? _buildEmpty()
              : _buildTable(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⚖️', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 12),
            Text(
              I18n.t('compare.empty'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              I18n.t('compare.emptyDesc'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => context.go('/cities'),
              icon: const Icon(Icons.explore_outlined),
              label: Text(I18n.t('favorites.explore')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Üst başlık satırı (mekanlar)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const SizedBox(width: 130), // sol etiket alanı için boşluk
                ..._places.map((p) => _PlaceHeader(
                      place: p,
                      onRemove: () => _remove(p),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Karşılaştırma satırları
          _buildRow(
            I18n.t('place.category'),
            _places.map((p) => p.category.isEmpty ? '-' : p.category).toList(),
          ),
          _buildRow(
            I18n.t('compare.rating'),
            _places.map((p) => '⭐ ${p.rating.toStringAsFixed(1)}').toList(),
          ),
          _buildRow(
            I18n.t('place.admission'),
            _places
                .map((p) => p.isFree
                    ? '✅ ${I18n.t('place.free')}'
                    : (p.admissionFee ?? '-'))
                .toList(),
          ),
          _buildRow(
            I18n.t('place.hours'),
            _places.map((p) => p.openingHours ?? '-').toList(),
            maxLines: 3,
          ),
          _buildRow(
            I18n.t('place.address'),
            _places.map((p) => p.address ?? '-').toList(),
            maxLines: 2,
          ),
          _buildRow(
            I18n.t('place.phone'),
            _places.map((p) => p.phone ?? '-').toList(),
          ),
          _buildRow(
            I18n.t('compare.featured'),
            _places.map((p) => p.isFeatured ? '⭐ Evet' : '—').toList(),
          ),
          _buildRow(
            I18n.t('compare.gps'),
            _places
                .map((p) => p.latitude != null && p.longitude != null
                    ? '📍 Var'
                    : '—')
                .toList(),
          ),
          const SizedBox(height: 16),
          Text(
            I18n.t('compare.maxNote'),
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, List<String> values, {int maxLines = 1}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Sol etiket sütunu (sticky değil ama boyutlu)
            Container(
              width: 130,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: AppTheme.cardBorder),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            // Değerler
            ...values.map((v) => Container(
                  width: 160,
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: AppTheme.cardBorder),
                    ),
                  ),
                  child: Text(
                    v,
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textPrimary,
                      height: 1.3,
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

/// Karşılaştırma tablosunun üst sütun başlığı (mekan kartı + sil butonu)
class _PlaceHeader extends StatelessWidget {
  final Place place;
  final VoidCallback onRemove;
  const _PlaceHeader({required this.place, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/place/${place.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primary, AppTheme.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(place.emoji, style: const TextStyle(fontSize: 24)),
                const Spacer(),
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              place.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
