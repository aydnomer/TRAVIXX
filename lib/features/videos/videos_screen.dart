import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';

class VideosScreen extends StatelessWidget {
  const VideosScreen({super.key});

  static const _videos = [
    {
      'title': 'İstanbul: Tarihin Kalbi',
      'place': 'İstanbul',
      'emoji': '🕌',
      'duration': '8:42',
      'thumb': 'https://img.youtube.com/vi/ZYFKMuXn8Xg/hqdefault.jpg',
      'url': 'https://www.youtube.com/watch?v=ZYFKMuXn8Xg',
    },
    {
      'title': 'Kapadokya: Balon Turu ve Peri Bacaları',
      'place': 'Nevşehir',
      'emoji': '🎈',
      'duration': '12:15',
      'thumb': 'https://img.youtube.com/vi/H3-F5y2MHFQ/hqdefault.jpg',
      'url': 'https://www.youtube.com/watch?v=H3-F5y2MHFQ',
    },
    {
      'title': 'Ege Kıyıları: Bodrum ve Çevresi',
      'place': 'Muğla',
      'emoji': '⛵',
      'duration': '15:30',
      'thumb': 'https://img.youtube.com/vi/GD10d6a6MXg/hqdefault.jpg',
      'url': 'https://www.youtube.com/watch?v=GD10d6a6MXg',
    },
    {
      'title': 'Safranbolu: Osmanlı Mirası',
      'place': 'Karabük',
      'emoji': '🏘️',
      'duration': '10:05',
      'thumb': 'https://img.youtube.com/vi/bxJxJ37FNWU/hqdefault.jpg',
      'url': 'https://www.youtube.com/watch?v=bxJxJ37FNWU',
    },
    {
      'title': 'Pamukkale Travertenleri',
      'place': 'Denizli',
      'emoji': '🏊',
      'duration': '9:18',
      'thumb': 'https://img.youtube.com/vi/2HHxOPzTRoE/hqdefault.jpg',
      'url': 'https://www.youtube.com/watch?v=2HHxOPzTRoE',
    },
    {
      'title': 'Antalya: Sahil ve Tarih',
      'place': 'Antalya',
      'emoji': '🌊',
      'duration': '11:47',
      'thumb': 'https://img.youtube.com/vi/o-lDlzKN8OI/hqdefault.jpg',
      'url': 'https://www.youtube.com/watch?v=o-lDlzKN8OI',
    },
    {
      'title': 'Trabzon: Karadeniz\'in İncisi',
      'place': 'Trabzon',
      'emoji': '🏔️',
      'duration': '13:22',
      'thumb': 'https://img.youtube.com/vi/HT2PxOjxFoI/hqdefault.jpg',
      'url': 'https://www.youtube.com/watch?v=HT2PxOjxFoI',
    },
    {
      'title': 'Efes Antik Kenti Rehberi',
      'place': 'İzmir',
      'emoji': '🏛️',
      'duration': '14:55',
      'thumb': 'https://img.youtube.com/vi/3KD0XH0vvnw/hqdefault.jpg',
      'url': 'https://www.youtube.com/watch?v=3KD0XH0vvnw',
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
        title: const Text('Video Rehberler'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '▶ YouTube',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              "Türkiye'nin en güzel şehirlerini video rehberlerle keşfet",
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: _videos.length,
              itemBuilder: (context, i) {
                final v = _videos[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _open(v['url'] as String),
                    child: Row(
                      children: [
                        // Thumbnail + play overlay
                        SizedBox(
                          width: 130,
                          height: 90,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                v['thumb'] as String,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppTheme.primary,
                                  child: Center(
                                    child: Text(
                                      v['emoji'] as String,
                                      style: const TextStyle(fontSize: 32),
                                    ),
                                  ),
                                ),
                              ),
                              Container(color: Colors.black26),
                              const Center(
                                child: Icon(
                                  Icons.play_circle_filled,
                                  color: Colors.white,
                                  size: 38,
                                ),
                              ),
                              Positioned(
                                bottom: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    v['duration'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Bilgi
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  v['title'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(v['emoji'] as String,
                                        style: const TextStyle(fontSize: 13)),
                                    const SizedBox(width: 4),
                                    Text(
                                      v['place'] as String,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    '▶  İzle',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
