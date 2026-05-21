import 'package:flutter/material.dart';
import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';

/// 6 dilli seçici. Tıklayınca dropdown açılır,
/// dil seçilince I18n.setLanguage çağrılır — tüm app yeniden render olur.
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key, this.dark = false});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: I18n.language,
      builder: (context, currentLang, _) {
        final selected = I18n.languages.firstWhere(
          (l) => l.code == currentLang,
          orElse: () => I18n.languages.first,
        );
        return PopupMenuButton<String>(
          tooltip: 'Dil / Language',
          onSelected: (code) => I18n.setLanguage(code),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (_) => I18n.languages
              .map(
                (l) => PopupMenuItem<String>(
                  value: l.code,
                  child: Row(
                    children: [
                      Text(l.flag, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Text(l.name, style: const TextStyle(fontSize: 13)),
                      if (l.code == currentLang) ...[
                        const Spacer(),
                        const Icon(
                          Icons.check,
                          size: 16,
                          color: AppTheme.primary,
                        ),
                      ],
                    ],
                  ),
                ),
              )
              .toList(),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: dark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: dark
                    ? Colors.white.withValues(alpha: 0.25)
                    : AppTheme.cardBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(selected.flag, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  selected.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: dark ? Colors.white : AppTheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 14,
                  color: dark
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
