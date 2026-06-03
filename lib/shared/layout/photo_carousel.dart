import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';

/// Birden fazla fotoğrafı 3 saniyede bir otomatik döndüren carousel.
/// Tek foto varsa statik gösterir; foto yoksa [fallback] döner.
class PhotoCarousel extends StatefulWidget {
  final List<String> images;
  final Widget fallback;
  final BoxFit fit;
  final bool showDots;
  final Duration interval;

  const PhotoCarousel({
    super.key,
    required this.images,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.showDots = true,
    this.interval = const Duration(seconds: 3),
  });

  @override
  State<PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<PhotoCarousel> {
  final PageController _ctrl = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(PhotoCarousel old) {
    super.didUpdateWidget(old);
    if (old.images.length != widget.images.length) {
      _index = 0;
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    _timer?.cancel();
    if (widget.images.length < 2) return;
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted || !_ctrl.hasClients) return;
      _index = (_index + 1) % widget.images.length;
      _ctrl.animateToPage(_index,
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return widget.fallback;
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _ctrl,
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) => Image.network(
            widget.images[i],
            fit: widget.fit,
            errorBuilder: (_, __, ___) => widget.fallback,
            loadingBuilder: (ctx, child, progress) =>
                progress == null ? child : widget.fallback,
          ),
        ),
        if (widget.showDots && widget.images.length > 1)
          Positioned(
            bottom: DT.s8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.images.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: DT.anim,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.white70,
                    borderRadius: DT.brPill,
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}
