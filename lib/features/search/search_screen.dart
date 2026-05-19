import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/database_service.dart';
import '../../core/utils/overpass_service.dart';
import '../places/place_model.dart';

class SearchScreen extends StatefulWidget {
  final String initialQuery;
  const SearchScreen({super.key, this.initialQuery = ''});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _ctrl;
  Timer? _debounce;
  List<Place> _results = [];
  List<OverpassPlace> _osmResults = [];
  bool _loading = false;
  bool _osmLoading = false;
  bool _searched = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.isNotEmpty) {
      _runSearch(widget.initialQuery);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _runSearch(value);
    });
  }

  Future<void> _runSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _osmResults = [];
        _searched = false;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _osmResults = [];
      _lastQuery = q;
    });
    try {
      final results = await DatabaseService.searchPlaces(q);
      if (!mounted || _lastQuery != q) return;
      setState(() {
        _results = results;
        _searched = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _searched = true;
        _loading = false;
      });
    }
  }

  Future<void> _runWideSearch() async {
    final q = _lastQuery;
    if (q.isEmpty || _osmLoading) return;
    setState(() => _osmLoading = true);
    try {
      final osm = await OverpassService.searchTurkey(q);
      if (!mounted || _lastQuery != q) return;
      setState(() {
        _osmResults = osm;
        _osmLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _osmLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: TextField(
          controller: _ctrl,
          autofocus: widget.initialQuery.isEmpty,
          onChanged: _onChanged,
          onSubmitted: _runSearch,
          textInputAction: TextInputAction.search,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: const InputDecoration(
            hintText: 'Mekan ara...',
            hintStyle: TextStyle(color: Colors.white70, fontSize: 15),
            border: InputBorder.none,
          ),
          cursorColor: Colors.white,
        ),
        actions: [
          if (_ctrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _ctrl.clear();
                _runSearch('');
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_searched) {
      return _buildHint();
    }
    // Hem Supabase boş hem OSM aranmamış → boş durum
    if (_results.isEmpty && _osmResults.isEmpty && !_osmLoading) {
      return _buildEmptyWithWideSearch();
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (_results.isNotEmpty) ...[
          const _SectionHeader(
            label: 'Travixx mekanları',
            icon: Icons.verified,
          ),
          const SizedBox(height: 8),
          ..._results.map((p) => _ResultCard(place: p)),
        ],
        const SizedBox(height: 16),
        // OSM bölümü
        if (_osmResults.isNotEmpty) ...[
          const _SectionHeader(
            label: 'OpenStreetMap (geniş arama)',
            icon: Icons.public,
          ),
          const SizedBox(height: 8),
          ..._osmResults.map((p) => _OsmResultCard(place: p)),
        ] else if (_osmLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_results.isNotEmpty)
          _buildWideSearchPrompt(),
      ],
    );
  }

  Widget _buildEmptyWithWideSearch() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              '"$_lastQuery" için Travixx\'te sonuç yok',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'OpenStreetMap üzerinden Türkiye genelinde aramak ister misin?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _osmLoading ? null : _runWideSearch,
              icon: _osmLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.public, size: 18),
              label: Text(_osmLoading ? 'Aranıyor...' : 'Geniş Ara'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideSearchPrompt() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.accentOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppTheme.accentOrange.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.public, color: AppTheme.accentOrange, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'OpenStreetMap üzerinden\nTürkiye genelinde de arayalım mı?',
              style: TextStyle(fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: _runWideSearch,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.accentOrange,
            ),
            child: const Text('Geniş Ara',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHint() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.search, size: 72, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Mekan veya şehir adı yazmaya başla',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          SizedBox(height: 4),
          Text(
            'Türkçe ve İngilizce arama yapılır',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _OsmResultCard extends StatelessWidget {
  final OverpassPlace place;
  const _OsmResultCard({required this.place});

  Future<void> _openInMaps() async {
    final uri = Uri.parse(
        'https://www.openstreetmap.org/?mlat=${place.lat}&mlon=${place.lng}#map=17/${place.lat}/${place.lng}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _openInMaps,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child:
                    Text(place.emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
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
                  ),
                  if (place.nameEn != null && place.nameEn != place.name) ...[
                    const SizedBox(height: 2),
                    Text(
                      place.nameEn!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.accentOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          place.displayCategory,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.accentOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.public,
                          size: 12, color: AppTheme.textSecondary),
                      const SizedBox(width: 2),
                      const Text(
                        'OSM',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new,
                color: AppTheme.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Place place;
  const _ResultCard({required this.place});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/place/${place.id}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(place.emoji,
                    style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
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
                  ),
                  if (place.nameEn.isNotEmpty &&
                      place.nameEn != place.name) ...[
                    const SizedBox(height: 2),
                    Text(
                      place.nameEn,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (place.category.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accentOrange
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
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
                      ],
                      const Icon(Icons.star, size: 13, color: AppTheme.gold),
                      const SizedBox(width: 2),
                      Text(
                        place.rating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
