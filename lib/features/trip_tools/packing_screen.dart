import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';

/// Eşya listesi (packing list) — checkbox işaretle, kalıcı kayıt.
class PackingScreen extends StatefulWidget {
  const PackingScreen({super.key});

  @override
  State<PackingScreen> createState() => _PackingScreenState();
}

class _PackingScreenState extends State<PackingScreen> {
  static const _prefsKey = 'packing_state';

  late List<_PackingCategory> _categories;

  @override
  void initState() {
    super.initState();
    _categories = _defaultList();
    _load();
  }

  List<_PackingCategory> _defaultList() => [
        _PackingCategory(
          emoji: '👕',
          name: 'Giyim',
          items: [
            _PackingItem('T-shirt / gömlek'),
            _PackingItem('Pantolon / şort'),
            _PackingItem('İç çamaşırı'),
            _PackingItem('Mont / hırka'),
            _PackingItem('Pijama'),
            _PackingItem('Ayakkabı'),
          ],
        ),
        _PackingCategory(
          emoji: '🧴',
          name: 'Kişisel Bakım',
          items: [
            _PackingItem('Diş fırçası + macun'),
            _PackingItem('Şampuan / sabun'),
            _PackingItem('Havlu'),
            _PackingItem('Deodorant'),
            _PackingItem('Güneş kremi'),
          ],
        ),
        _PackingCategory(
          emoji: '💊',
          name: 'Sağlık',
          items: [
            _PackingItem('İlaçlar'),
            _PackingItem('Yara bandı'),
            _PackingItem('Ağrı kesici'),
          ],
        ),
        _PackingCategory(
          emoji: '📱',
          name: 'Elektronik',
          items: [
            _PackingItem('Telefon + şarj'),
            _PackingItem('Powerbank'),
            _PackingItem('Kulaklık'),
            _PackingItem('Kamera'),
          ],
        ),
        _PackingCategory(
          emoji: '📄',
          name: 'Belgeler & Para',
          items: [
            _PackingItem('Kimlik / pasaport'),
            _PackingItem('Otel rezervasyonu'),
            _PackingItem('Nakit + kart'),
            _PackingItem('Bilet (uçak/otobüs)'),
          ],
        ),
      ];

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      for (final c in _categories) {
        for (final i in c.items) {
          if (json[i.name] == true) i.checked = true;
        }
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = <String, bool>{};
      for (final c in _categories) {
        for (final i in c.items) {
          map[i.name] = i.checked;
        }
      }
      await prefs.setString(_prefsKey, jsonEncode(map));
    } catch (_) {}
  }

  int get _total => _categories.fold(0, (s, c) => s + c.items.length);
  int get _done =>
      _categories.fold(0, (s, c) => s + c.items.where((i) => i.checked).length);

  @override
  Widget build(BuildContext context) {
    final pct = _total > 0 ? _done / _total : 0.0;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(I18n.t('packing.title')),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: Column(
        children: [
          // Progress bar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(color: Color(0xFFEFF6FF)),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      '$_done / $_total',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(pct * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentOrange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: Colors.white,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.accentOrange),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _categories.length,
              itemBuilder: (context, c) {
                final cat = _categories[c];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                        child: Row(
                          children: [
                            Text(cat.emoji,
                                style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 8),
                            Text(
                              cat.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...cat.items.map((item) {
                        return CheckboxListTile(
                          dense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 14),
                          value: item.checked,
                          activeColor: AppTheme.accentOrange,
                          onChanged: (v) {
                            setState(() => item.checked = v ?? false);
                            _save();
                          },
                          title: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 13,
                              decoration: item.checked
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: item.checked
                                  ? AppTheme.textSecondary
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PackingCategory {
  final String emoji;
  final String name;
  final List<_PackingItem> items;
  _PackingCategory({required this.emoji, required this.name, required this.items});
}

class _PackingItem {
  final String name;
  bool checked;
  _PackingItem(this.name) : checked = false;
}
