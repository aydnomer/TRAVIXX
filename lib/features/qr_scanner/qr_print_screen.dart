import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/database_service.dart';
import '../../core/utils/print_service.dart';
import '../../core/utils/qr_service.dart';
import '../cities/city_model.dart';
import '../places/place_model.dart';

/// Mekanlara asılacak QR kodlarını üreten sayfa.
/// Şehir seçilir, o şehrin mekanları için QR'lar ızgara halinde çıkar;
/// web'de tarayıcının yazdır penceresiyle kağıda/PDF'e basılabilir.
class QrPrintScreen extends StatefulWidget {
  const QrPrintScreen({super.key});

  @override
  State<QrPrintScreen> createState() => _QrPrintScreenState();
}

class _QrPrintScreenState extends State<QrPrintScreen> {
  List<City> _cities = const [];
  City? _city;
  List<Place> _places = const [];
  bool _loading = true;

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
        _cities = cities;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectCity(City? city) async {
    if (city == null) return;
    setState(() {
      _city = city;
      _loading = true;
    });
    try {
      final places = await DatabaseService.getPlacesByCity(city.id);
      if (!mounted) return;
      setState(() {
        _places = places;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(I18n.t('qrPrint.title')),
        actions: [
          if (kIsWeb && _places.isNotEmpty)
            IconButton(
              tooltip: I18n.t('qrPrint.print'),
              icon: const Icon(Icons.print_outlined),
              onPressed: PrintService.printPage,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<City>(
              initialValue: _city,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: I18n.t('qrPrint.selectCity'),
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final c in _cities)
                  DropdownMenuItem(value: c, child: Text(c.name)),
              ],
              onChanged: _selectCity,
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _city == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            I18n.t('qrPrint.hint'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppTheme.textSecondary),
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: _places.length,
                        itemBuilder: (_, i) => _QrTile(place: _places[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

class _QrTile extends StatelessWidget {
  final Place place;
  const _QrTile({required this.place});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.cardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Expanded(
            child: QrImageView(
              data: QrService.linkForPlace(place.id),
              backgroundColor: Colors.white,
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            place.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary),
          ),
          const Text(
            'Travixx',
            style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
