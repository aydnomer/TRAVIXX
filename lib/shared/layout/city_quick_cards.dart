import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';
import '../../features/cities/city_model.dart';

/// Yatay scroll şehir kartı. Web 180x120, mobil 140x90.
/// Şehir adı alt solda beyaz, üzerine koyu overlay.
class CityCard extends StatelessWidget {
  final City city;
  final VoidCallback onTap;
  final double width;
  final double height;
  const CityCard({
    super.key,
    required this.city,
    required this.onTap,
    this.width = 180,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = (city.imageUrl != null && city.imageUrl!.isNotEmpty);
    return InkWell(
      onTap: onTap,
      borderRadius: DT.brCard,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: DT.primaryLight,
          borderRadius: DT.brCard,
          border: DT.boxBorder,
          image: hasImage
              ? DecorationImage(
                  image: NetworkImage(city.imageUrl!), fit: BoxFit.cover)
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!hasImage)
              Center(
                  child: Text(city.emoji.isNotEmpty ? city.emoji : '🏙️',
                      style: const TextStyle(fontSize: 28))),
            // Koyu overlay (alt)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: height * 0.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: DT.s12,
              bottom: DT.s12,
              right: DT.s12,
              child: Text(
                city.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, fontWeight: DT.wMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Ne yapmak istiyorsun?" 2x2 grid kartı: sol renkli ikon kutusu + başlık/açıklama.
class QuickActionCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const QuickActionCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<QuickActionCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: DT.anim,
          padding: const EdgeInsets.all(DT.s16),
          decoration: BoxDecoration(
            color: DT.surface,
            borderRadius: DT.brCard,
            border:
                Border.all(color: _hover ? DT.primary : DT.border, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.12),
                  borderRadius: DT.brSmall,
                ),
                alignment: Alignment.center,
                child: Icon(widget.icon, size: 20, color: widget.color),
              ),
              const SizedBox(width: DT.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.title, style: DT.label14Medium),
                    const SizedBox(height: 2),
                    Text(widget.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DT.muted12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
