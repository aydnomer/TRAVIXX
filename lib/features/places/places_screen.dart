import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../core/utils/database_service.dart";
import "../../shared/widgets/skeleton.dart";
import "place_model.dart";

class PlacesScreen extends StatefulWidget {
  final String cityId;
  final String cityName;
  const PlacesScreen({super.key, required this.cityId, required this.cityName});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  List<Place> _places = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    try {
      final places = await DatabaseService.getPlacesByCity(widget.cityId);
      setState(() {
        _places = places;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.cityName),
        backgroundColor: const Color(0xFF1a2744),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? Skeleton.list(count: 8)
          : _places.isEmpty
              ? const Center(child: Text("Bu sehirde mekan bulunamadi"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _places.length,
                  itemBuilder: (context, index) {
                    final place = _places[index];
                    return InkWell(
                      onTap: () => context.push('/place/${place.id}'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0x141a2744),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(place.emoji,
                                  style: const TextStyle(fontSize: 30)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(place.name,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1a2744))),
                                const SizedBox(height: 4),
                                Text(place.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0x26f97316),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(place.category,
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFFf97316),
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.star,
                                        size: 14, color: Color(0xFFeab308)),
                                    const SizedBox(width: 2),
                                    Text(place.rating.toString(),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    );
                  },
                ),
    );
  }
}
