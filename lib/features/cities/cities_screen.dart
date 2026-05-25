import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../core/i18n/i18n.dart";
import "../../core/theme/app_theme.dart";
import "../../core/utils/database_service.dart";
import "../../shared/widgets/skeleton.dart";
import "city_model.dart";

class CitiesScreen extends StatefulWidget {
  const CitiesScreen({super.key});

  @override
  State<CitiesScreen> createState() => _CitiesScreenState();
}

class _CitiesScreenState extends State<CitiesScreen> {
  List<City> _allCities = [];
  List<City> _filteredCities = [];
  bool _loading = true;
  String _search = "";
  String _selectedRegion = "Tümü";

  // İç anahtar (DB ile eşleşir) → i18n key
  static const List<(String, String)> _regions = [
    ("Tümü", "region.all"),
    ("Marmara", "region.marmara"),
    ("Ege", "region.aegean"),
    ("Akdeniz", "region.mediterranean"),
    ("İç Anadolu", "region.centralAnatolia"),
    ("Karadeniz", "region.blackSea"),
    ("Doğu Anadolu", "region.easternAnatolia"),
    ("Güneydoğu Anadolu", "region.southeasternAnatolia"),
  ];

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    try {
      final cities = await DatabaseService.getCities();
      if (!mounted) return;
      setState(() {
        _allCities = cities;
        _filteredCities = cities;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    final q = _search.toLowerCase().trim();
    setState(() {
      _filteredCities = _allCities.where((c) {
        final matchesSearch = q.isEmpty ||
            c.name.toLowerCase().contains(q) ||
            c.nameEn.toLowerCase().contains(q) ||
            c.region.toLowerCase().contains(q);
        final matchesRegion =
            _selectedRegion == "Tümü" || c.region == _selectedRegion;
        return matchesSearch && matchesRegion;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(I18n.t('cities.title')),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Arama çubuğu
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              onChanged: (v) {
                _search = v;
                _applyFilters();
              },
              decoration: InputDecoration(
                hintText: I18n.t('cities.searchHint'),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Bölge filtre chip'leri
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _regions.length,
              itemBuilder: (context, i) {
                final (key, i18nKey) = _regions[i];
                final selected = key == _selectedRegion;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(I18n.t(i18nKey)),
                    selected: selected,
                    onSelected: (_) {
                      _selectedRegion = key;
                      _applyFilters();
                    },
                    selectedColor: AppTheme.primary,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppTheme.primary,
                      fontSize: 12,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: selected
                            ? AppTheme.primary
                            : AppTheme.cardBorder,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Sonuç sayısı
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  "${_filteredCities.length} şehir",
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_selectedRegion != "Tümü" || _search.isNotEmpty) ...[
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      _search = "";
                      _selectedRegion = "Tümü";
                      _applyFilters();
                    },
                    icon: const Icon(Icons.clear, size: 14),
                    label: Text(I18n.t('common.clear'),
                        style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? Skeleton.grid(count: 8)
                : _filteredCities.isEmpty
                    ? _buildEmpty()
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _filteredCities.length,
                        itemBuilder: (context, index) {
                          final city = _filteredCities[index];
                          return _CityCard(city: city);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          const Text(
            "Sonuç bulunamadı",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Farklı bir arama veya bölge dene",
            style:
                TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CityCard extends StatelessWidget {
  final City city;
  const _CityCard({required this.city});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push("/city/${city.id}", extra: city.name),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(city.emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(
              city.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              city.region,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "${city.placeCount} mekan",
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.accentOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
