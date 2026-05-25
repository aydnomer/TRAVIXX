import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_theme.dart';

/// Genel kullanılabilir shimmer skeleton widget'ları.
/// Yükleme sırasında "yer tutucu" gösterir, hissedilen hızı artırır.
class Skeleton {
  /// Dikey liste kartı (örn: mekan listesi)
  static Widget listCard({
    double height = 84,
    EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: 12),
  }) {
    return _Shimmer(
      child: Container(
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 14,
                    width: 160,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: 110,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 8,
                    width: 80,
                    color: Colors.grey.shade300,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }

  /// Şehir grid kartı (2 sütunlu grid için)
  static Widget gridCard({double height = 130}) {
    return _Shimmer(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              const Spacer(),
              Container(
                height: 12,
                width: 90,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 6),
              Container(
                height: 9,
                width: 60,
                color: Colors.grey.shade300,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Yatay scroll için minik kart (collections / recent)
  static Widget horizontalCard({double width = 220, double height = 130}) {
    return _Shimmer(
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  /// Çoklu kart shimmer (n adet listCard tekrarı)
  static Widget list({int count = 6}) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: count,
      itemBuilder: (_, __) => listCard(),
    );
  }

  /// Grid shimmer (2 sütun)
  static Widget grid({int count = 6}) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: count,
      itemBuilder: (_, __) => gridCard(),
    );
  }
}

/// İç sarmalayıcı — light/dark tema otomatik
class _Shimmer extends StatelessWidget {
  final Widget child;
  const _Shimmer({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark
          ? AppTheme.darkSurface
          : Colors.grey.shade200,
      highlightColor: isDark
          ? AppTheme.darkCardBorder
          : Colors.grey.shade100,
      period: const Duration(milliseconds: 1200),
      child: child,
    );
  }
}
