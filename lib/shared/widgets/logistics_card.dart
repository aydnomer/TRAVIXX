import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';

class LogisticsCard extends StatelessWidget {
  final String searchQuery;
  const LogisticsCard({super.key, required this.searchQuery});

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final encoded = Uri.encodeComponent(searchQuery);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.luggage_outlined, color: AppTheme.accentOrange, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Seyahat Planla',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$searchQuery için hizmetler',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _btn(
                icon: Icons.hotel_outlined,
                label: 'Otel Bul',
                color: const Color(0xFF003580),
                onTap: () => _open(
                  'https://www.booking.com/searchresults.tr.html?ss=$encoded',
                ),
              ),
              const SizedBox(width: 8),
              _btn(
                icon: Icons.flight_outlined,
                label: 'Uçuş Bul',
                color: const Color(0xFF0770E3),
                onTap: () => _open('https://www.skyscanner.com.tr/'),
              ),
              const SizedBox(width: 8),
              _btn(
                icon: Icons.directions_car_outlined,
                label: 'Araç Kirala',
                color: AppTheme.accentOrange,
                onTap: () => _open(
                  'https://www.rentalcars.com/SearchResults.do?locationSearchString=$encoded',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _btn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
