import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/database_service.dart';
import '../../shared/widgets/skeleton.dart';
import 'place_model.dart';

class PlacesScreen extends StatefulWidget {
  final String cityId;
  final String cityName;
  /// embedded: true olduğunda Scaffold ve SliverAppBar kaldırılır.
  /// CityGuideScreen içinde tab olarak kullanım için.
  final bool embedded;
  const PlacesScreen({
    super.key,
    required this.cityId,
    required this.cityName,
    this.embedded = false,
  });

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  // ── Veri ──────────────────────────────────────────────────────
  List<Place> _all = [];
  List<Place> _filtered = [];
  bool _loading = true;

  // ── Filtre ────────────────────────────────────────────────────
  String _selectedCat = 'Tümü';
  List<String> _categories = ['Tümü'];

  // ── Arama ─────────────────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  bool _searchVisible = false;

  // ── Görünüm ───────────────────────────────────────────────────
  bool _isGrid = false;

  // ── Sıralama ──────────────────────────────────────────────────
  _SortMode _sort = _SortMode.rating;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Veri yükleme ──────────────────────────────────────────────

  Future<void> _loadPlaces() async {
    try {
      final places = await DatabaseService.getPlacesByCity(widget.cityId);
      final cats = ['Tümü', ...{for (final p in places) p.category}];
      if (mounted) {
        setState(() {
          _all = places;
          _categories = cats;
          _loading = false;
        });
        _applyFilter();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    var list = List<Place>.from(_all);

    // Kategori
    if (_selectedCat != 'Tümü') {
      list = list.where((p) => p.category == _selectedCat).toList();
    }

    // Arama
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q))
          .toList();
    }

    // Sıralama
    switch (_sort) {
      case _SortMode.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case _SortMode.name:
        list.sort((a, b) => a.name.compareTo(b.name));
      case _SortMode.free:
        list.sort((a, b) {
          if (a.isFree && !b.isFree) return -1;
          if (!a.isFree && b.isFree) return 1;
          return b.rating.compareTo(a.rating);
        });
    }

    setState(() => _filtered = list);
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scrollView = CustomScrollView(
      slivers: [
        // AppBar'ı sadece bağımsız kullanımda göster (embedded=false)
        if (!widget.embedded) _buildAppBar(),
        if (_searchVisible)
          SliverToBoxAdapter(child: _buildSearchBar()),
        SliverToBoxAdapter(child: _buildCategoryChips()),
        SliverToBoxAdapter(child: _buildToolbar()),
        if (_loading)
          SliverToBoxAdapter(child: Skeleton.list(count: 6))
        else if (_filtered.isEmpty)
          SliverFillRemaining(child: _buildEmpty())
        else if (_isGrid)
          _buildGrid()
        else
          _buildList(),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );

    // Embedded modda sadece scroll view döner (dış Scaffold'dan gelir)
    if (widget.embedded) return scrollView;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: scrollView,
    );
  }

  // ── App Bar ───────────────────────────────────────────────────

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.cityName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!_loading)
            Text(
              '${_all.length} mekan',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
        ],
      ),
      pinned: true,
      actions: [
        IconButton(
          icon: Icon(
            _searchVisible ? Icons.search_off : Icons.search,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              _searchVisible = !_searchVisible;
              if (!_searchVisible) {
                _searchCtrl.clear();
                _applyFilter();
              }
            });
          },
        ),
        IconButton(
          icon: Icon(
            _isGrid ? Icons.view_list : Icons.grid_view,
            color: Colors.white,
          ),
          onPressed: () => setState(() => _isGrid = !_isGrid),
        ),
      ],
    );
  }

  // ── Arama Çubuğu ──────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        autofocus: true,
        onChanged: (_) => _applyFilter(),
        decoration: InputDecoration(
          hintText: '${widget.cityName}\'de mekan ara...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    _applyFilter();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ── Kategori Chipleri ─────────────────────────────────────────

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = _categories[i];
          final active = cat == _selectedCat;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCat = cat);
              _applyFilter();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? AppTheme.primary : AppTheme.cardBorder,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      active ? FontWeight.bold : FontWeight.w500,
                  color: active ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Araç Çubuğu (sayaç + sıralama) ───────────────────────────

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Text(
            _loading
                ? 'Yükleniyor...'
                : '${_filtered.length} sonuç',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const Spacer(),
          // Sıralama menüsü
          PopupMenuButton<_SortMode>(
            initialValue: _sort,
            onSelected: (mode) {
              setState(() => _sort = mode);
              _applyFilter();
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: _SortMode.rating,
                child: Row(children: [
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  SizedBox(width: 8),
                  Text('Puana göre'),
                ]),
              ),
              const PopupMenuItem(
                value: _SortMode.name,
                child: Row(children: [
                  Icon(Icons.sort_by_alpha, size: 16),
                  SizedBox(width: 8),
                  Text('İsme göre'),
                ]),
              ),
              const PopupMenuItem(
                value: _SortMode.free,
                child: Row(children: [
                  Icon(Icons.money_off, size: 16, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Ücretsiz önce'),
                ]),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sort, size: 14,
                      color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    _sortLabel,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  const Icon(Icons.expand_more, size: 14,
                      color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _sortLabel {
    switch (_sort) {
      case _SortMode.rating:
        return 'Puan';
      case _SortMode.name:
        return 'İsim';
      case _SortMode.free:
        return 'Ücretsiz';
    }
  }

  // ── Liste Görünümü ────────────────────────────────────────────

  Widget _buildList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) => _PlaceListCard(
          place: _filtered[i],
          onTap: () => context.push('/place/${_filtered[i].id}'),
        ),
        childCount: _filtered.length,
      ),
    );
  }

  // ── Grid Görünümü ─────────────────────────────────────────────

  Widget _buildGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, i) => _PlaceGridCard(
            place: _filtered[i],
            onTap: () => context.push('/place/${_filtered[i].id}'),
          ),
          childCount: _filtered.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.82,
        ),
      ),
    );
  }

  // ── Boş Durum ─────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            _searchCtrl.text.isNotEmpty
                ? '"${_searchCtrl.text}" için sonuç bulunamadı'
                : '$_selectedCat kategorisinde mekan yok',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              _searchCtrl.clear();
              setState(() => _selectedCat = 'Tümü');
              _applyFilter();
            },
            child: const Text('Filtreleri Temizle'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Liste Kartı
// ══════════════════════════════════════════════════════════════════

class _PlaceListCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;
  const _PlaceListCard({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasImage = place.images.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              // Sol: fotoğraf veya emoji
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16)),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: hasImage
                      ? Image.network(
                          place.images[0],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _emojiBg(place.emoji),
                        )
                      : _emojiBg(place.emoji),
                ),
              ),
              // Sağ: bilgi
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        place.description,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Kategori
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.accentOrange
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              place.category,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.accentOrange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Rating
                          const Icon(Icons.star,
                              size: 13, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            place.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Ücretsiz
                          if (place.isFree)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Ücretsiz',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.chevron_right,
                    color: AppTheme.textSecondary, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emojiBg(String emoji) => Container(
        color: AppTheme.primary.withValues(alpha: 0.06),
        child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 34))),
      );
}

// ══════════════════════════════════════════════════════════════════
// Grid Kartı
// ══════════════════════════════════════════════════════════════════

class _PlaceGridCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;
  const _PlaceGridCard({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasImage = place.images.isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto / emoji arka plan
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  hasImage
                      ? Image.network(
                          place.images[0],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _emojiBg(place.emoji),
                        )
                      : _emojiBg(place.emoji),
                  // Alt gradient
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(8, 20, 8, 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.65)
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star,
                              size: 11, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            place.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (place.isFree)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Ücretsiz',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 9),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Alt bilgi
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(9, 7, 9, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    place.category,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emojiBg(String emoji) => Container(
        color: AppTheme.primary.withValues(alpha: 0.06),
        child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 40))),
      );
}

// ── Sıralama Modu ─────────────────────────────────────────────────

enum _SortMode { rating, name, free }
