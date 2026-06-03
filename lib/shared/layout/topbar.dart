import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/design_tokens.dart';

/// Web üst bar (56px sticky): sol başlık, orta arama, sağ hava+bildirim+avatar.
class Topbar extends StatelessWidget {
  final String title;
  final String? temperature; // örn "26°"
  final bool hasNotification;
  final String avatarText;
  final VoidCallback onProfileTap;

  const Topbar({
    super.key,
    required this.title,
    required this.avatarText,
    required this.onProfileTap,
    this.temperature,
    this.hasNotification = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: DT.s24),
      decoration: const BoxDecoration(
        color: DT.surface,
        border: Border(bottom: DT.side),
      ),
      child: Row(
        children: [
          // Sol: sayfa başlığı
          Text(title, style: DT.t16),
          const SizedBox(width: DT.s32),
          // Orta: arama çubuğu (max 480px)
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _SearchBar(onTap: () => context.push('/search')),
              ),
            ),
          ),
          const SizedBox(width: DT.s32),
          // Sağ: hava chip
          if (temperature != null) ...[
            _WeatherChip(temperature: temperature!),
            const SizedBox(width: DT.s12),
          ],
          // Bildirim
          _IconBtn(
            icon: Icons.notifications_outlined,
            badge: hasNotification,
            onTap: () => context.push('/notifications'),
          ),
          const SizedBox(width: DT.s12),
          // Avatar
          InkWell(
            onTap: onProfileTap,
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: DT.primary,
              child: Text(avatarText,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13, fontWeight: DT.wMedium)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: DT.brPill,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: DT.s12),
        decoration: BoxDecoration(
          color: DT.bg,
          borderRadius: DT.brPill,
          border: DT.boxBorder,
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 18, color: DT.textMuted),
            const SizedBox(width: DT.s8),
            const Expanded(
              child: Text('Şehir veya mekan ara...', style: DT.muted12),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: DT.s8, vertical: 2),
              decoration: BoxDecoration(
                color: DT.primaryLight,
                borderRadius: DT.brPill,
              ),
              child: const Text('81 il',
                  style: TextStyle(
                      fontSize: 12, color: DT.primaryDark, fontWeight: DT.wMedium)),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherChip extends StatelessWidget {
  final String temperature;
  const _WeatherChip({required this.temperature});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DT.s12, vertical: DT.s8),
      decoration: BoxDecoration(
        color: DT.bg,
        borderRadius: DT.brPill,
        border: DT.boxBorder,
      ),
      child: Row(
        children: [
          const Icon(Icons.wb_sunny_outlined, size: 18, color: DT.catCastle),
          const SizedBox(width: DT.s4),
          Text(temperature, style: DT.label13Medium),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final bool badge;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap, this.badge = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: DT.brSmall,
      child: Padding(
        padding: const EdgeInsets.all(DT.s8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: 20, color: DT.textSecondary),
            if (badge)
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration:
                      const BoxDecoration(color: DT.danger, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
