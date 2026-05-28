import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';

class AccommodationScreen extends StatelessWidget {
  const AccommodationScreen({super.key});

  static const _categories = [
    {
      'emoji': '🏨',
      'title': 'Oteller',
      'desc': "Tüm Türkiye'de otel ara ve karşılaştır",
      'color': 0xFF003580,
      'url': 'https://www.booking.com/searchresults.tr.html?ss=T%C3%BCrkiye',
      'tags': ['Merkezi konum', 'Kahvaltı dahil', 'Havuz'],
    },
    {
      'emoji': '🏡',
      'title': 'Kiralık Villalar',
      'desc': 'Ölüdeniz, Datça, Göcek ve daha fazlası',
      'color': 0xFFE67E22,
      'url': 'https://www.airbnb.com.tr/s/Turkey/homes?property_type_id[]=17',
      'tags': ['Özel havuz', 'Aile için', 'Manzaralı'],
    },
    {
      'emoji': '⛺',
      'title': 'Kamp Alanları',
      'desc': "Doğayla iç içe kamp deneyimi",
      'color': 0xFF27AE60,
      'url': 'https://www.google.com/search?q=t%C3%BCrkiye+kamp+alanlar%C4%B1',
      'tags': ['Doğa', 'Uygun fiyat', 'Macera'],
    },
    {
      'emoji': '🌿',
      'title': 'Glamping',
      'desc': 'Çadır konforu, otel lüksü bir arada',
      'color': 0xFF8E44AD,
      'url': 'https://www.google.com/search?q=t%C3%BCrkiye+glamping',
      'tags': ['Lüks çadır', 'Çevre dostu', 'Instagramlık'],
    },
    {
      'emoji': '🏘️',
      'title': 'Butik & Yerel Evler',
      'desc': 'Otantik yerel deneyimler yaşa',
      'color': 0xFFB7950B,
      'url': 'https://www.airbnb.com.tr/s/Turkey/homes',
      'tags': ['Ev sıcaklığı', 'Yerel kültür', 'Otantik'],
    },
    {
      'emoji': '🚐',
      'title': 'Karavan & Çadır Araçları',
      'desc': 'Özgür seyahat, karavan kiralama',
      'color': 0xFF2980B9,
      'url': 'https://www.google.com/search?q=t%C3%BCrkiye+karavan+kiralama',
      'tags': ['Özgürlük', 'Esnek rota', 'Ekonomik'],
    },
  ];

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Konaklama Seçenekleri'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Her tarza uygun konaklama seçeneği bul',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
            ),
            ..._categories.map((cat) {
              final color = Color(cat['color'] as int);
              final tags = cat['tags'] as List<String>;
              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _open(cat['url'] as String),
                  child: Column(
                    children: [
                      // Başlık alanı
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withValues(alpha: 0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              cat['emoji'] as String,
                              style: const TextStyle(fontSize: 40),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat['title'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    cat['desc'] as String,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios,
                                color: Colors.white70, size: 16),
                          ],
                        ),
                      ),
                      // Etiketler
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(
                          children: tags
                              .map((tag) => Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: color.withValues(alpha: 0.25)),
                                    ),
                                    child: Text(
                                      tag,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
