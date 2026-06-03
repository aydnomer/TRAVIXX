import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/design_tokens.dart';
import 'nav_destinations.dart';

/// Mobil alt navigasyon (64px + safe area). 5 sekme eşit genişlik.
/// Orta sekme (Harita) büyük yeşil pill. Aktif sekmede label görünür.
class BottomNav extends StatelessWidget {
  final String currentRoute;
  const BottomNav({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final dests = NavDestinations.mobile;
    return Container(
      decoration: const BoxDecoration(
        color: DT.surface,
        border: Border(top: DT.side),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(dests.length, (i) {
              final d = dests[i];
              final active = NavDestinations.isActive(currentRoute, d.route);
              final isCenter = i == 2; // Harita ortada
              return Expanded(
                child: isCenter
                    ? _CenterTab(dest: d, active: active)
                    : _Tab(dest: d, active: active),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final NavDest dest;
  final bool active;
  const _Tab({required this.dest, required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? DT.primary : DT.textMuted;
    return InkWell(
      onTap: () => context.go(dest.route),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(dest.icon, size: 24, color: color),
          if (active) ...[
            const SizedBox(height: DT.s4),
            Text(dest.label,
                style: const TextStyle(
                    fontSize: 12, color: DT.primary, fontWeight: DT.wMedium)),
          ],
        ],
      ),
    );
  }
}

class _CenterTab extends StatelessWidget {
  final NavDest dest;
  final bool active;
  const _CenterTab({required this.dest, required this.active});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(dest.route),
      child: Center(
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: active ? DT.primary : DT.primaryLight,
            borderRadius: DT.brCard,
          ),
          alignment: Alignment.center,
          child: Icon(dest.icon,
              size: 28, color: active ? Colors.white : DT.primary),
        ),
      ),
    );
  }
}
