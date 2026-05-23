import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/i18n.dart';
import 'collection_model.dart';

/// Bir tematik koleksiyon kartı (large=true tam genişlik, false=yatay liste).
class CollectionCard extends StatelessWidget {
  final PlaceCollection collection;
  final bool large;
  const CollectionCard({
    super.key,
    required this.collection,
    this.large = false,
  });

  Color _hex(String h) {
    final clean = h.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final colors = [
      _hex(collection.coverGradientStart),
      _hex(collection.coverGradientEnd),
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/collection/${collection.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: large ? double.infinity : 220,
          height: large ? 160 : 130,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.last.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Dekoratif büyük emoji (sağ üst, yarı saydam)
              Positioned(
                top: -10,
                right: -10,
                child: Opacity(
                  opacity: 0.18,
                  child: Text(
                    collection.emoji,
                    style: TextStyle(fontSize: large ? 140 : 110),
                  ),
                ),
              ),
              // İçerik
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.emoji,
                      style: TextStyle(fontSize: large ? 28 : 22),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          collection.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: large ? 18 : 14,
                            fontWeight: FontWeight.bold,
                            shadows: const [
                              Shadow(
                                color: Colors.black38,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${collection.placeCount} ${I18n.t('collections.places')}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
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
