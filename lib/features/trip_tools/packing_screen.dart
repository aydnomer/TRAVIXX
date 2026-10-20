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
          labelKey: 'tt.packing.cat.clothing',
          items: [
            _PackingItem('T-shirt / gömlek', 'tt.packing.item.tshirt'),
            _PackingItem('Pantolon / şort', 'tt.packing.item.trousers'),
            _PackingItem('İç çamaşırı', 'tt.packing.item.underwear'),
            _PackingItem('Mont / hırka', 'tt.packing.item.jacket'),
            _PackingItem('Pijama', 'tt.packing.item.pyjamas'),
            _PackingItem('Ayakkabı', 'tt.packing.item.shoes'),
          ],
        ),
        _PackingCategory(
          emoji: '🧴',
          labelKey: 'tt.packing.cat.care',
          items: [
            _PackingItem('Diş fırçası + macun', 'tt.packing.item.toothbrush'),
            _PackingItem('Şampuan / sabun', 'tt.packing.item.shampoo'),
            _PackingItem('Havlu', 'tt.packing.item.towel'),
            _PackingItem('Deodorant', 'tt.packing.item.deodorant'),
            _PackingItem('Güneş kremi', 'tt.packing.item.sunscreen'),
          ],
        ),
        _PackingCategory(
          emoji: '💊',
          labelKey: 'tt.packing.cat.health',
          items: [
            _PackingItem('İlaçlar', 'tt.packing.item.medicine'),
            _PackingItem('Yara bandı', 'tt.packing.item.plasters'),
            _PackingItem('Ağrı kesici', 'tt.packing.item.painkiller'),
          ],
        ),
        _PackingCategory(
          emoji: '📱',
          labelKey: 'tt.packing.cat.electronics',
          items: [
            _PackingItem('Telefon + şarj', 'tt.packing.item.phone'),
            _PackingItem('Powerbank', 'tt.packing.item.powerbank'),
            _PackingItem('Kulaklık', 'tt.packing.item.headphones'),
            _PackingItem('Kamera', 'tt.packing.item.camera'),
          ],
        ),
        _PackingCategory(
          emoji: '📄',
          labelKey: 'tt.packing.cat.documents',
          items: [
            _PackingItem('Kimlik / pasaport', 'tt.packing.item.id'),
            _PackingItem('Otel rezervasyonu', 'tt.packing.item.hotel'),
            _PackingItem('Nakit + kart', 'tt.packing.item.cash'),
            _PackingItem('Bilet (uçak/otobüs)', 'tt.packing.item.ticket'),
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
          // Kayıt anahtarı sabit Türkçe id'dir — eski kayıtlar da yüklenir.
          if (json[i.id] == true) i.checked = true;
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
          map[i.id] = i.checked;
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
                              I18n.t(cat.labelKey),
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
                            I18n.t(item.labelKey),
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
  final String labelKey;
  final List<_PackingItem> items;
  _PackingCategory(
      {required this.emoji, required this.labelKey, required this.items});
}

class _PackingItem {
  /// Kalıcı kayıt anahtarı (SharedPreferences) — değiştirilmemeli.
  final String id;

  /// Ekranda gösterilen metnin i18n anahtarı.
  final String labelKey;
  bool checked;
  _PackingItem(this.id, this.labelKey) : checked = false;
}
