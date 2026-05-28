import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ai_planner_service.dart';
import '../../core/utils/database_service.dart';
import '../cities/city_model.dart';

class TripWizardScreen extends StatefulWidget {
  const TripWizardScreen({super.key});

  @override
  State<TripWizardScreen> createState() => _TripWizardScreenState();
}

class _TripWizardScreenState extends State<TripWizardScreen> {
  int _step = 0;
  City? _selectedCity;
  int _days = 2;
  String _budget = 'orta';
  final Set<String> _interests = {};

  bool _loadingCities = true;
  List<City> _allCities = [];
  List<City> _filteredCities = [];
  final _searchCtrl = TextEditingController();

  TripPlan? _plan;
  bool _planning = false;

  static const _budgets = [
    {
      'key': 'ekonomik',
      'label': 'Ekonomik',
      'emoji': '💰',
      'desc': 'Ücretsiz ve düşük bütçeli mekanlar öncelikli',
    },
    {
      'key': 'orta',
      'label': 'Orta Bütçe',
      'emoji': '💳',
      'desc': 'Her türden mekan, dengeli seçim',
    },
    {
      'key': 'lüks',
      'label': 'Lüks',
      'emoji': '✨',
      'desc': 'Özel ve ücretli mekanlar öne çıkar',
    },
  ];

  static const _interestOptions = [
    {'key': 'Tarih & Kültür', 'emoji': '🏛️'},
    {'key': 'Doğa & Açık Hava', 'emoji': '🌿'},
    {'key': 'Gastronomi', 'emoji': '🍽️'},
    {'key': 'Sanat & Müzeler', 'emoji': '🎨'},
    {'key': 'Aktif & Macera', 'emoji': '🧗'},
    {'key': 'Romantik', 'emoji': '💕'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    final cities = await DatabaseService.getCities();
    if (mounted) {
      setState(() {
        _allCities = cities;
        _filteredCities = cities;
        _loadingCities = false;
      });
    }
  }

  void _filterCities(String q) {
    final lower = q.toLowerCase();
    setState(() {
      _filteredCities = _allCities
          .where((c) =>
              c.name.toLowerCase().contains(lower) ||
              c.nameEn.toLowerCase().contains(lower))
          .toList();
    });
  }

  Future<void> _generate() async {
    if (_selectedCity == null) return;
    setState(() => _planning = true);
    final plan = await AiPlannerService.planWithFilters(
      city: _selectedCity!,
      days: _days,
      budget: _budget,
      interests: _interests.toList(),
    );
    if (mounted) {
      setState(() {
        _plan = plan;
        _planning = false;
        _step = 4;
      });
    }
  }

  bool get _canNext => _step != 0 || _selectedCity != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Akıllı Rota Planlayıcı'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step == 4) {
              setState(() {
                _step = 3;
                _plan = null;
              });
            } else if (_step > 0) {
              setState(() => _step--);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: Column(
        children: [
          if (_step < 4) _buildStepIndicator(),
          Expanded(child: _buildContent()),
          if (_step < 4) _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    const labels = ['Şehir', 'Süre', 'Bütçe', 'İlgiler'];
    return Container(
      color: AppTheme.primary,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Row(
        children: List.generate(4, (i) {
          final done = i < _step;
          final active = i == _step;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: active ? 36 : 28,
                        height: active ? 36 : 28,
                        decoration: BoxDecoration(
                          color: done
                              ? AppTheme.accentOrange
                              : (active ? Colors.white : Colors.white24),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: done
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    color: active ? AppTheme.primary : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: active ? 16 : 13,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        labels[i],
                        style: TextStyle(
                          color: active ? Colors.white : Colors.white54,
                          fontSize: 11,
                          fontWeight: active ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < 3)
                  Container(
                    height: 2,
                    width: 16,
                    color: i < _step ? AppTheme.accentOrange : Colors.white24,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildContent() {
    switch (_step) {
      case 0:
        return _buildCityStep();
      case 1:
        return _buildDaysStep();
      case 2:
        return _buildBudgetStep();
      case 3:
        return _buildInterestsStep();
      case 4:
        return _buildResultStep();
      default:
        return const SizedBox();
    }
  }

  // ─── Adım 1: Şehir ─────────────────────────────────────────────

  Widget _buildCityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Nereyi gezmek istiyorsun?', '🗺️ 81 il arasından şehir seç'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _filterCities,
            decoration: InputDecoration(
              hintText: 'Şehir ara...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        Expanded(
          child: _loadingCities
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _filteredCities.length,
                  itemBuilder: (_, i) {
                    final c = _filteredCities[i];
                    final selected = _selectedCity?.id == c.id;
                    return ListTile(
                      leading: Text(c.emoji, style: const TextStyle(fontSize: 22)),
                      title: Text(
                        c.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        c.region,
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: selected
                          ? const Icon(Icons.check_circle, color: AppTheme.accentOrange)
                          : null,
                      tileColor: selected
                          ? AppTheme.accentOrange.withValues(alpha: 0.08)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      onTap: () => setState(() => _selectedCity = c),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ─── Adım 2: Gün Sayısı ─────────────────────────────────────────

  Widget _buildDaysStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            'Kaç gün sürecek?',
            '${_selectedCity?.emoji ?? ""} ${_selectedCity?.name ?? ""}',
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Text(
                  '$_days',
                  style: const TextStyle(
                    fontSize: 88,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                    height: 1,
                  ),
                ),
                const Text(
                  'Gün',
                  style: TextStyle(fontSize: 22, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.accentOrange,
              thumbColor: AppTheme.accentOrange,
              inactiveTrackColor: Colors.grey.shade200,
              overlayColor: AppTheme.accentOrange.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: _days.toDouble(),
              min: 1,
              max: 7,
              divisions: 6,
              label: '$_days gün',
              onChanged: (v) => setState(() => _days = v.round()),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final n = i + 1;
              final active = n == _days;
              return GestureDetector(
                onTap: () => setState(() => _days = n),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: active ? AppTheme.accentOrange : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: active ? AppTheme.accentOrange : Colors.grey.shade300,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$n',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: active ? Colors.white : AppTheme.primary,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── Adım 3: Bütçe ──────────────────────────────────────────────

  Widget _buildBudgetStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader('Bütçen nasıl?', 'Rotanı bütçene göre optimize edelim'),
          const SizedBox(height: 20),
          ..._budgets.map((b) {
            final key = b['key'] as String;
            final active = _budget == key;
            return GestureDetector(
              onTap: () => setState(() => _budget = key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: active ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: active ? AppTheme.primary : Colors.grey.shade200,
                    width: active ? 2 : 1,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Text(b['emoji'] as String, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b['label'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: active ? Colors.white : AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            b['desc'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              color: active ? Colors.white70 : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (active)
                      const Icon(Icons.check_circle, color: AppTheme.accentOrange, size: 24),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Adım 4: İlgi Alanları ──────────────────────────────────────

  Widget _buildInterestsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader('İlgi alanların?', 'İstediğin kadar seç (opsiyonel)'),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _interestOptions.map((opt) {
              final key = opt['key'] as String;
              final active = _interests.contains(key);
              return GestureDetector(
                onTap: () => setState(() {
                  if (active) {
                    _interests.remove(key);
                  } else {
                    _interests.add(key);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: active ? AppTheme.accentOrange : Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: active ? AppTheme.accentOrange : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: AppTheme.accentOrange.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(opt['emoji'] as String, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        key,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: active ? Colors.white : AppTheme.primary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.accentOrange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppTheme.accentOrange, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Hiç seçmezsen rota en yüksek puanlı mekanlardan oluşur.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sonuç ──────────────────────────────────────────────────────

  Widget _buildResultStep() {
    if (_planning) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.accentOrange),
            SizedBox(height: 20),
            Text(
              'Rota oluşturuluyor...',
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }
    if (_plan == null || _plan!.itinerary.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😔', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text(
              '${_selectedCity?.name} için yeterli mekan bulunamadı.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() => _step = 0),
              child: const Text('Baştan Başla'),
            ),
          ],
        ),
      );
    }
    final plan = _plan!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Özet kartı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${plan.city.emoji} ${plan.city.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _chip('📅 ${plan.days} Gün'),
                    _chip({
                          'ekonomik': '💰 Ekonomik',
                          'orta': '💳 Orta Bütçe',
                          'lüks': '✨ Lüks',
                        }[_budget] ??
                        ''),
                    ..._interests.map(_chip),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Günler
          ...plan.itinerary.map((day) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentOrange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${day.dayNumber}. Gün',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  ...day.places.asMap().entries.map((e) {
                    final slot = day.slotLabel(e.key);
                    final place = e.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(place.emoji,
                                style: const TextStyle(fontSize: 22)),
                          ),
                        ),
                        title: Text(
                          place.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slot,
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.accentOrange),
                            ),
                            Text(
                              place.category,
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                        trailing: place.isFree
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Ücretsiz',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                        onTap: () => context.push('/place/${place.id}'),
                      ),
                    );
                  }),
                  const SizedBox(height: 6),
                ],
              )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() {
                _step = 0;
                _plan = null;
              }),
              icon: const Icon(Icons.refresh),
              label: const Text('Yeni Rota Oluştur'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─── Alt Bar ────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        children: [
          if (_step > 0) ...[
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () => setState(() => _step--),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Geri'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: _step == 3
                ? ElevatedButton(
                    onPressed: _generate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      '🗺️  Rota Oluştur',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _canNext ? () => setState(() => _step++) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Devam  →',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── Yardımcılar ────────────────────────────────────────────────

  Widget _stepHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white30),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}
