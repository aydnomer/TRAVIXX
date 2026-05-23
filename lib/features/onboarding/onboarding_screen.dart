import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/i18n/i18n.dart';

/// İlk açılışta gösterilen 4 sayfalık tanıtım.
/// "Görüldü" işareti SharedPreferences'a yazılır, tekrar açılmaz.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const _prefsKey = 'onboarding_seen';

  /// Daha önce gösterildi mi?
  static Future<bool> hasBeenSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefsKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, true);
    } catch (_) {}
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  late final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      emoji: '✈️',
      titleKey: 'onboarding.p1.title',
      descKey: 'onboarding.p1.desc',
      gradient: [Color(0xFF1A2744), Color(0xFF2D3E5E)],
    ),
    _OnboardingPage(
      emoji: '📍',
      titleKey: 'onboarding.p2.title',
      descKey: 'onboarding.p2.desc',
      gradient: [Color(0xFF7C3AED), Color(0xFFEC4899)],
    ),
    _OnboardingPage(
      emoji: '📱',
      titleKey: 'onboarding.p3.title',
      descKey: 'onboarding.p3.desc',
      gradient: [Color(0xFFF97316), Color(0xFFEAB308)],
    ),
    _OnboardingPage(
      emoji: '🌍',
      titleKey: 'onboarding.p4.title',
      descKey: 'onboarding.p4.desc',
      gradient: [Color(0xFF0891B2), Color(0xFF16A34A)],
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await OnboardingScreen.markSeen();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;
    final current = _pages[_index];
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: current.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Atla butonu
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextButton(
                    onPressed: _finish,
                    child: Text(
                      I18n.t('onboarding.skip'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              // Sayfa içeriği
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final p = _pages[i];
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(p.emoji, style: const TextStyle(fontSize: 140)),
                          const SizedBox(height: 40),
                          Text(
                            I18n.t(p.titleKey),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            I18n.t(p.descKey),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Dot indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 28 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              // İleri/Başla butonu
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: current.gradient.first,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      isLast
                          ? I18n.t('onboarding.start')
                          : I18n.t('onboarding.next'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final String emoji;
  final String titleKey;
  final String descKey;
  final List<Color> gradient;
  const _OnboardingPage({
    required this.emoji,
    required this.titleKey,
    required this.descKey,
    required this.gradient,
  });
}
