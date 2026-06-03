import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/design_tokens.dart';

/// Mobil üst bar (56px sticky): sol logo, orta lokasyon chip, sağ bildirim+avatar.
class MobileHeader extends StatelessWidget {
  final String locationName;
  final bool hasNotification;
  final String avatarText;
  final VoidCallback onProfileTap;
  final VoidCallback? onLocationTap;

  const MobileHeader({
    super.key,
    required this.locationName,
    required this.avatarText,
    required this.onProfileTap,
    this.onLocationTap,
    this.hasNotification = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: DT.s16),
      decoration: const BoxDecoration(
        color: DT.surface,
        border: Border(bottom: DT.side),
      ),
      child: Row(
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                    color: DT.primary, borderRadius: DT.brSmall),
                alignment: Alignment.center,
                child: const Icon(Icons.travel_explore,
                    size: 15, color: Colors.white),
              ),
              const SizedBox(width: DT.s8),
              const Text('Travixx', style: DT.label14Medium),
            ],
          ),
          const Spacer(),
          // Lokasyon chip
          InkWell(
            onTap: onLocationTap,
            borderRadius: DT.brPill,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: DT.s12, vertical: 6),
              decoration: BoxDecoration(
                color: DT.primaryLight,
                borderRadius: DT.brPill,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 16, color: DT.primary),
                  const SizedBox(width: DT.s4),
                  Text(locationName,
                      style: const TextStyle(
                          fontSize: 13,
                          color: DT.primaryDark,
                          fontWeight: DT.wMedium)),
                  const Icon(Icons.keyboard_arrow_down,
                      size: 16, color: DT.primary),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Bildirim
          InkWell(
            onTap: () => context.push('/notifications'),
            borderRadius: DT.brSmall,
            child: Padding(
              padding: const EdgeInsets.all(DT.s4),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_outlined,
                      size: 22, color: DT.textSecondary),
                  if (hasNotification)
                    Positioned(
                      right: -1,
                      top: -1,
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
          const SizedBox(width: DT.s8),
          // Avatar
          InkWell(
            onTap: onProfileTap,
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: DT.primary,
              child: Text(avatarText,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: DT.wMedium)),
            ),
          ),
        ],
      ),
    );
  }
}
