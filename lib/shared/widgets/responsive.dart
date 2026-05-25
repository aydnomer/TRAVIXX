import 'package:flutter/material.dart';

/// Web'de aşırı geniş ekranlarda içeriği maksimum genişlikte tutar.
/// Mobilde tam genişlik kullanır.
///
/// Kullanım:
///   ResponsiveBox(child: ListView(...))
class ResponsiveBox extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveBox({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}

/// Hover olayına tepki veren kart sarmalayıcı.
/// Web'de fare üzerine gelince hafifçe büyür ve gölgesi artar.
class HoverCard extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;

  const HoverCard({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    this.onTap,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..scaleByDouble(
            _hovering ? 1.02 : 1.0,
            _hovering ? 1.02 : 1.0,
            1.0,
            1.0,
          ),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          boxShadow: _hovering
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: widget.borderRadius,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
