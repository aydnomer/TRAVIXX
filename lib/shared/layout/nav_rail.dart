import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/design_tokens.dart';
import 'nav_destinations.dart';

/// Web sol kenar dikey nav rail (64px, icon-only).
/// Aktif ikonda sol kenarda 3px yeşil çizgi, hover'da yuvarlak açık-yeşil zemin.
class NavRail extends StatelessWidget {
  final String currentRoute;
  final bool hasNotification;
  final String avatarText;
  final VoidCallback onProfileTap;

  const NavRail({
    super.key,
    required this.currentRoute,
    required this.avatarText,
    required this.onProfileTap,
    this.hasNotification = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      decoration: const BoxDecoration(
        color: DT.surface,
        border: Border(right: DT.side),
      ),
      child: Column(
        children: [
          const SizedBox(height: DT.s24),
          // Logo
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: DT.primary,
              borderRadius: DT.brSmall,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.travel_explore, size: 20, color: Colors.white),
          ),
          const SizedBox(height: DT.s16),
          const Divider(height: 1, thickness: 1, color: DT.border, indent: 16, endIndent: 16),
          const SizedBox(height: DT.s12),
          // Ana hedefler
          ...NavDestinations.main.map((d) => _RailItem(
                icon: d.icon,
                label: d.label,
                active: NavDestinations.isActive(currentRoute, d.route),
                onTap: () => context.go(d.route),
              )),
          const Spacer(),
          // Bildirimler
          _RailItem(
            icon: Icons.notifications_outlined,
            label: 'Bildirimler',
            active: NavDestinations.isActive(currentRoute, '/notifications'),
            badge: hasNotification,
            onTap: () => context.push('/notifications'),
          ),
          const SizedBox(height: DT.s8),
          // Profil avatarı → drawer
          _Tooltip(
            label: 'Profil',
            child: InkWell(
              onTap: onProfileTap,
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(DT.s8),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: DT.primary,
                  child: Text(avatarText,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12, fontWeight: DT.wMedium)),
                ),
              ),
            ),
          ),
          const SizedBox(height: DT.s24),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool badge;
  final VoidCallback onTap;
  const _RailItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return _Tooltip(
      label: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DT.s4, horizontal: DT.s8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Aktif sol çizgi
            if (active)
              Positioned(
                left: -8,
                top: 8,
                bottom: 8,
                child: Container(width: 3, color: DT.primary),
              ),
            InkWell(
              onTap: onTap,
              borderRadius: DT.brSmall,
              hoverColor: DT.primaryLight,
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, size: 22, color: active ? DT.primary : DT.textSecondary),
                    if (badge)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                              color: DT.danger, shape: BoxShape.circle),
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
  }
}

/// CSS :hover benzeri — sağda label gösteren saf Flutter Tooltip (JS yok).
class _Tooltip extends StatelessWidget {
  final String label;
  final Widget child;
  const _Tooltip({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      preferBelow: false,
      verticalOffset: 0,
      margin: const EdgeInsets.only(left: 60),
      decoration: BoxDecoration(color: DT.textMain, borderRadius: DT.brSmall),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      child: child,
    );
  }
}
