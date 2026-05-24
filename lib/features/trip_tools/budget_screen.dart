import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';

/// Basit gezi bütçesi hesaplayıcısı.
/// Kullanıcı kategori bazlı giderleri girer, toplam ve günlük ortalama hesaplanır.
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  int _days = 3;
  final _items = <_BudgetItem>[
    _BudgetItem('🏨', 'Konaklama', 500),
    _BudgetItem('🍽️', 'Yemek', 200),
    _BudgetItem('🚗', 'Ulaşım', 150),
    _BudgetItem('🎫', 'Müze/Bilet', 100),
    _BudgetItem('🛍️', 'Alışveriş', 100),
    _BudgetItem('🎲', 'Diğer', 50),
  ];

  double get _dailyTotal =>
      _items.fold(0.0, (sum, i) => sum + i.dailyAmount);
  double get _grandTotal => _dailyTotal * _days;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(I18n.t('budget.title')),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Gün seçici
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: AppTheme.accentOrange),
                const SizedBox(width: 10),
                Text(I18n.t('budget.days'),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => setState(() => _days = (_days - 1).clamp(1, 30)),
                ),
                Text(
                  _days.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => _days = (_days + 1).clamp(1, 30)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Kategori girdileri
          ...List.generate(_items.length, (i) {
            return _BudgetRow(
              item: _items[i],
              onChange: (v) => setState(() => _items[i].dailyAmount = v),
            );
          }),
          const SizedBox(height: 16),
          // Toplam kart
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.accentOrange, Color(0xFFEAB308)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  I18n.t('budget.estimatedTotal'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_grandTotal.toStringAsFixed(0)} TL',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_dailyTotal.toStringAsFixed(0)} TL × $_days ${I18n.t('budget.days').toLowerCase()}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Eşya listesi sayfasına git butonu
          OutlinedButton.icon(
            onPressed: () => context.push('/packing'),
            icon: const Icon(Icons.luggage),
            label: Text(I18n.t('packing.title')),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetItem {
  final String emoji;
  final String name;
  double dailyAmount;
  _BudgetItem(this.emoji, this.name, this.dailyAmount);
}

class _BudgetRow extends StatelessWidget {
  final _BudgetItem item;
  final ValueChanged<double> onChange;
  const _BudgetRow({required this.item, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ),
          SizedBox(
            width: 110,
            child: TextField(
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              controller: TextEditingController(
                text: item.dailyAmount.toStringAsFixed(0),
              ),
              onChanged: (v) {
                final parsed = double.tryParse(v);
                if (parsed != null) onChange(parsed);
              },
              decoration: const InputDecoration(
                suffixText: 'TL/gün',
                suffixStyle: TextStyle(fontSize: 11),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
