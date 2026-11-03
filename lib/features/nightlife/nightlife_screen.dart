import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/categories.dart';
import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/database_service.dart';
import '../../core/utils/gps_service.dart';
import '../../core/utils/price_service.dart';
import '../places/place_model.dart';
import '../prices/price_section.dart' show itemEmoji;

/// Tatil bölgesi: adı, merkezi ve arama yarıçapı.
class NightlifeHub {
  final String name;
  final double lat;
  final double lng;
  final double radiusKm;
  const NightlifeHub(this.name, this.lat, this.lng, this.radiusKm);
}

/// Beach club, gece kulübü, bar ve plajları tatil bölgesine göre listeler;
/// ziyaretçilerin bildirdiği fiyatları (şezlong, giriş, kokteyl) gösterir.
class NightlifeScreen extends StatefulWidget {
  /// Açılışta seçili bölge (ör. /nightlife?hub=Bodrum).
  final String? initialHub;
  const NightlifeScreen({super.key, this.initialHub});

  /// Turistlerin en çok gittiği eğlence bölgeleri.
  static const hubs = [
    NightlifeHub('Bodrum', 37.0344, 27.4305, 25),
    NightlifeHub('Çeşme · Alaçatı', 38.3020, 26.3400, 15),
    NightlifeHub('İzmir', 38.4370, 27.1428, 15),
    NightlifeHub('Antalya', 36.8848, 30.7040, 20),
    NightlifeHub('Alanya', 36.5440, 31.9990, 15),
    NightlifeHub('Kemer', 36.6000, 30.5600, 15),
    NightlifeHub('Kaş · Kalkan', 36.2019, 29.6377, 15),
    NightlifeHub('Fethiye · Ölüdeniz', 36.6216, 29.1164, 15),
    NightlifeHub('Marmaris', 36.8550, 28.2742, 12),
    NightlifeHub('Kuşadası', 37.8597, 27.2597, 12),
    NightlifeHub('İstanbul', 41.0340, 28.9850, 12),
  ];

  @override
  State<NightlifeScreen> createState() => _NightlifeScreenState();
}

/// Sekmeler: kimlik → (kategori, alt tür) eşleşmesi.
enum _Tab { all, beachClub, club, bar, beach }

class _NightlifeScreenState extends State<NightlifeScreen> {
  late NightlifeHub? _hub;
  ({double lat, double lng})? _myPos;
  _Tab _tab = _Tab.all;
  List<_Item> _items = const [];
  Map<String, List<PriceSummary>> _prices = const {};
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _hub = NightlifeScreen.hubs.firstWhere(
      (h) => h.name == widget.initialHub,
      orElse: () => NightlifeScreen.hubs.first,
    );
    _load();
  }

  Future<void> _useMyLocation() async {
    final pos = await GpsService.getCurrentPosition(useCache: false);
    if (!mounted) return;
    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(I18n.t('nl.noLocation'))));
      return;
    }
    setState(() {
      _hub = null;
      _myPos = (lat: pos.latitude, lng: pos.longitude);
    });
    _load();
  }

  Future<void> _load() async {
    final center = _hub != null
        ? (lat: _hub!.lat, lng: _hub!.lng)
        : _myPos ?? (lat: NightlifeScreen.hubs.first.lat, lng: NightlifeScreen.hubs.first.lng);
    final radius = _hub?.radiusKm ?? 20;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final places = await DatabaseService.getNearbyPlaces(
        center.lat,
        center.lng,
        limit: 200,
        categories: const [Categories.nightlife, Categories.beach],
        radiusKm: radius,
      );
      final items = places
          .where((p) => p.latitude != null && p.longitude != null)
          .map((p) => _Item(
                p,
                GpsService.distanceKm(
                    center.lat, center.lng, p.latitude!, p.longitude!),
              ))
          .toList();
      final prices =
          await PriceService.summaries(items.map((i) => i.place.id).toList());
      if (!mounted) return;
      setState(() {
        _items = items;
        _prices = prices;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  bool _inTab(Place p) {
    final sub = p.subcategory ?? '';
    switch (_tab) {
      case _Tab.all:
        return true;
      case _Tab.beachClub:
        return sub == 'Beach Club';
      case _Tab.club:
        return sub == 'Gece Kulübü';
      case _Tab.bar:
        return p.isNightlife && (sub == 'Bar' || sub == 'Pub');
      case _Tab.beach:
        return p.category == Categories.beach;
    }
  }

  /// Fiyatı bildirilmiş ve puanı olanlar öne; sonra yakınlık.
  List<_Item> get _visible {
    final list = _items.where((i) => _inTab(i.place)).toList();
    int score(_Item i) =>
        (_prices[i.place.id]?.length ?? 0) * 2 + (i.place.hasRating ? 1 : 0);
    list.sort((a, b) {
      final s = score(b).compareTo(score(a));
      return s != 0 ? s : a.km.compareTo(b.km);
    });
    return list;
  }

  String _tabLabel(_Tab t) => switch (t) {
        _Tab.all => I18n.t('common.all'),
        _Tab.beachClub => Categories.subLabel('Beach Club'),
        _Tab.club => Categories.subLabel('Gece Kulübü'),
        _Tab.bar => I18n.t('nl.barsPubs'),
        _Tab.beach => Categories.label(Categories.beach),
      };

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(I18n.t('nl.title')),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        actions: [
          IconButton(
            tooltip: I18n.t('nl.nearMe'),
            icon: const Icon(Icons.my_location),
            onPressed: _useMyLocation,
          ),
        ],
      ),
      body: Column(
        children: [
          _chipRow<NightlifeHub?>(
            values: [null, ...NightlifeScreen.hubs],
            selected: _hub,
            label: (h) => h?.name ?? '📍 ${I18n.t('nl.nearMe')}',
            onSelect: (h) {
              if (h == null) {
                _useMyLocation();
              } else {
                setState(() => _hub = h);
                _load();
              }
            },
            dark: true,
          ),
          _chipRow<_Tab>(
            values: _Tab.values,
            selected: _tab,
            label: _tabLabel,
            onSelect: (t) => setState(() => _tab = t),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error
                    ? _message(I18n.t('nl.loadFailed'), retry: true)
                    : visible.isEmpty
                        ? _message(I18n.t('nl.empty'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: visible.length + 1,
                              itemBuilder: (_, i) => i == 0
                                  ? _hint()
                                  : _card(visible[i - 1]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _chipRow<T>({
    required List<T> values,
    required T selected,
    required String Function(T) label,
    required void Function(T) onSelect,
    bool dark = false,
  }) {
    return Container(
      color: dark ? AppTheme.primary : Colors.white,
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        itemCount: values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final v = values[i];
          final sel = v == selected;
          return ChoiceChip(
            label: Text(label(v)),
            selected: sel,
            onSelected: (_) => onSelect(v),
            selectedColor: AppTheme.accentOrange,
            labelStyle: TextStyle(
              color: sel ? Colors.white : AppTheme.textPrimary,
              fontWeight: sel ? FontWeight.bold : FontWeight.w500,
            ),
          );
        },
      ),
    );
  }

  Widget _hint() => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(I18n.t('nl.hint'),
            style:
                const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      );

  Widget _message(String text, {bool retry = false}) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌙', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text(text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary)),
              if (retry)
                TextButton(onPressed: _load, child: Text(I18n.t('nl.retry'))),
            ],
          ),
        ),
      );

  Widget _card(_Item item) {
    final p = item.place;
    final prices = [...?_prices[p.id]]
      ..sort((a, b) => b.reports.compareTo(a.reports));
    final sub = p.subcategory;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.cardBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/place/${p.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.accentOrangeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(p.emoji, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (sub != null && sub.isNotEmpty)
                          Categories.subLabel(sub)
                        else
                          Categories.label(p.category),
                        '${item.km.toStringAsFixed(item.km < 10 ? 1 : 0)} km',
                        if (p.hasRating) '⭐ ${p.ratingLabel}',
                      ].join(' · '),
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    if (p.openingHours?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 2),
                      Text('🕒 ${p.openingHours}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                    const SizedBox(height: 6),
                    if (prices.isEmpty)
                      Text(I18n.t('nl.noPricesShort'),
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                              fontStyle: FontStyle.italic))
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: prices.take(3).map((s) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.goldBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${itemEmoji(s.item)} ~${PriceService.format(s.median, s.currency)}',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item {
  final Place place;
  final double km;
  const _Item(this.place, this.km);
}
