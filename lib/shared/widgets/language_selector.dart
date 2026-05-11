import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class LanguageSelector extends StatefulWidget {
  const LanguageSelector({super.key, this.dark = false});
  final bool dark;

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  String _selected = 'TR';

  final List<Map<String, String>> _langs = [
    {'code': 'TR', 'flag': '🇹🇷', 'name': 'Türkçe'},
    {'code': 'EN', 'flag': '🇬🇧', 'name': 'English'},
    {'code': 'DE', 'flag': '🇩🇪', 'name': 'Deutsch'},
    {'code': 'AR', 'flag': '🇸🇦', 'name': 'العربية'},
    {'code': 'FR', 'flag': '🇫🇷', 'name': 'Français'},
    {'code': 'RU', 'flag': '🇷🇺', 'name': 'Русский'},
  ];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (val) => setState(() => _selected = val),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => _langs
          .map(
            (l) => PopupMenuItem(
              value: l['code'],
              child: Row(
                children: [
                  Text(l['flag']!, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Text(l['name']!, style: const TextStyle(fontSize: 13)),
                  if (l['code'] == _selected) ...[
                    const Spacer(),
                    const Icon(Icons.check, size: 16, color: AppTheme.primary),
                  ],
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: widget.dark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.dark
                ? Colors.white.withValues(alpha: 0.25)
                : AppTheme.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language,
              size: 16,
              color: widget.dark ? Colors.white : AppTheme.primary,
            ),
            const SizedBox(width: 5),
            Text(
              _selected,
              style: TextStyle(
                fontSize: 12,
                color: widget.dark ? Colors.white : AppTheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: widget.dark
                  ? Colors.white.withValues(alpha: 0.7)
                  : AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
