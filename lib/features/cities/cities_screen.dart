import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../core/utils/database_service.dart";
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

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    try {
      final cities = await DatabaseService.getCities();
      setState(() {
        _allCities = cities;
        _filteredCities = cities;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _onSearch(String value) {
    setState(() {
      _filteredCities = _allCities
          .where((c) =>
              c.name.toLowerCase().contains(value.toLowerCase()) ||
              c.region.toLowerCase().contains(value.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Sehirler"),
        backgroundColor: const Color(0xFF1a2744),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: "Sehir veya bolge ara...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCities.isEmpty
                    ? const Center(child: Text("Sehir bulunamadi"))
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
                color: Color(0xFF1a2744),
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
                color: const Color(0xFFf97316).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "${city.placeCount} mekan",
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFf97316),
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
