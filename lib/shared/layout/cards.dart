import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';
import '../../features/places/place_model.dart';
import 'photo_carousel.dart';

/// Web grid kartı (140px): üst 80px kategori-renkli ikon, alt 60px bilgi.
/// Hover'da border yeşile döner.
class PlaceCard extends StatefulWidget {
  final Place place;
  final double? distanceKm;
  final VoidCallback onTap;
  const PlaceCard(
      {super.key, required this.place, required this.onTap, this.distanceKm});

  @override
  State<PlaceCard> createState() => _PlaceCardState();
}

class _PlaceCardState extends State<PlaceCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = DT.categoryColor(widget.place.category);
    final icon = DT.categoryIcon(widget.place.category);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: DT.anim,
          height: 140,
          decoration: BoxDecoration(
            color: DT.surface,
            borderRadius: DT.brCard,
            border: Border.all(color: _hover ? DT.primary : DT.border, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Üst 80px — foto carousel (varsa) veya kategori ikonu
              SizedBox(
                height: 80,
                width: double.infinity,
                child: PhotoCarousel(
                  images: widget.place.images,
                  showDots: false,
                  fallback: Container(
                    color: color.withValues(alpha: 0.12),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 32, color: color),
                  ),
                ),
              ),
              // Alt 60px — bilgi
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DT.s12, vertical: DT.s8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(widget.place.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DT.label13Medium),
                      const SizedBox(height: DT.s4),
                      Row(
                        children: [
                          if (widget.distanceKm != null)
                            Text('${widget.distanceKm!.toStringAsFixed(1)} km',
                                style: DT.muted12),
                          if (widget.distanceKm != null && widget.place.isFree)
                            const SizedBox(width: DT.s8),
                          if (widget.place.isFree) const _FreeBadge(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mobil dikey liste satırı (72px): kare ikon + bilgi + badge/chevron.
class PlaceListRow extends StatelessWidget {
  final Place place;
  final double? distanceKm;
  final VoidCallback onTap;
  const PlaceListRow(
      {super.key, required this.place, required this.onTap, this.distanceKm});

  @override
  Widget build(BuildContext context) {
    final color = DT.categoryColor(place.category);
    final icon = DT.categoryIcon(place.category);
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: const BoxDecoration(border: Border(bottom: DT.side)),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              child: SizedBox(
                width: 52,
                height: 52,
                child: place.images.isNotEmpty
                    ? Image.network(
                        place.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _iconBox(color, icon),
                      )
                    : _iconBox(color, icon),
              ),
            ),
            const SizedBox(width: DT.s12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DT.label14Medium),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (place.category.isNotEmpty) place.category,
                      if (distanceKm != null)
                        '${distanceKm!.toStringAsFixed(1)} km',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DT.muted12,
                  ),
                ],
              ),
            ),
            const SizedBox(width: DT.s8),
            if (place.isFree) const _FreeBadge(),
            const SizedBox(width: DT.s4),
            const Icon(Icons.chevron_right, size: 20, color: DT.textMuted),
          ],
        ),
      ),
    );
  }
}

Widget _iconBox(Color color, IconData icon) => Container(
      color: color.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Icon(icon, size: 24, color: color),
    );

class _FreeBadge extends StatelessWidget {
  const _FreeBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DT.s8, vertical: 2),
      decoration: BoxDecoration(color: DT.primaryLight, borderRadius: DT.brPill),
      child: const Text('Ücretsiz',
          style: TextStyle(
              fontSize: 12, color: DT.primaryDark, fontWeight: DT.wMedium)),
    );
  }
}
