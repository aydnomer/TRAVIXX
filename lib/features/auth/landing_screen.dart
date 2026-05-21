import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/language_selector.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  bool _isLogin = true;
  bool _rememberMe = true;

  // ─── Sayfa scroll kontrolü ─────────────────────────────────────
  final ScrollController _pageScroll = ScrollController();

  // ─── Form Controller'ları (tek seferlik, dispose edilir) ───────
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // ─── Otomatik dönen şehir foto galerisi ────────────────────────
  int _photoIdx = 0;
  Timer? _photoTimer;

  // Şimdilik sadece foto'su garanti çalışan 2 destinasyon.
  // Sonradan kullanıcı kendi indirip ekleyecek diğerlerini.
  final List<Map<String, dynamic>> _destinations = [
    {
      'name': 'Kapadokya',
      'sub': 'Nevşehir · Sıcak hava balonları',
      'emoji': '🎈',
      'url':
          'https://images.unsplash.com/photo-1641128324972-af3212f0f6bd?w=1600&q=80&auto=format&fit=crop',
      'colors': [Color(0xFFdc2626), Color(0xFFf97316), Color(0xFFfbbf24)],
    },
    {
      'name': 'İstanbul',
      'sub': 'Galata Kulesi · Boğaz manzarası',
      'emoji': '🌉',
      'url':
          'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=1600&q=80&auto=format&fit=crop',
      'colors': [Color(0xFF1e3a8a), Color(0xFF1d4ed8), Color(0xFF60a5fa)],
    },
  ];

  // Yardımcı: sol her zaman ilki, sağ her zaman ikincisi.
  // Daha fazla destinasyon eklenince offset hesabı yeniden açılabilir.
  Map<String, dynamic> _leftDest() =>
      _destinations[_photoIdx % _destinations.length];
  Map<String, dynamic> _rightDest() => _destinations.length > 1
      ? _destinations[(_photoIdx + 1) % _destinations.length]
      : _destinations[0];

  // ─── Sayfa içi bölümlere kaydırma için key'ler ─────────────────
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _howWorksKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _authKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Carousel sadece 2'den fazla destinasyon varsa döner.
    // Şu an 2 var (Kapadokya + İstanbul) — statik kalıyor.
    if (_destinations.length > 2) {
      _photoTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) {
          setState(() {
            _photoIdx = (_photoIdx + 1) % _destinations.length;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _photoTimer?.cancel();
    _pageScroll.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_pageScroll.hasClients) {
      _pageScroll.animateTo(
        0,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isWide = w > 900;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: isWide ? _buildWeb() : _buildMobile(),
    );
  }

  // ─── WEB LAYOUT ──────────────────────────────────────────────
  Widget _buildWeb() {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: SingleChildScrollView(
            controller: _pageScroll,
            child: Column(
              children: [
                _buildHeroSection(),
                _buildFeaturesSection(key: _featuresKey),
                _buildPhotoStrip(),
                _buildHowItWorks(key: _howWorksKey),
                _buildTestimonials(),
                _buildAIChat(),
                _buildFooter(key: _aboutKey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── MOBILE LAYOUT ───────────────────────────────────────────
  Widget _buildMobile() {
    return SingleChildScrollView(
      controller: _pageScroll,
      child: Column(
        children: [
          _buildMobileHero(),
          _buildAuthCard(),
          _buildFeaturesSection(key: _featuresKey),
          _buildPhotoStrip(),
          _buildHowItWorks(key: _howWorksKey),
          _buildTestimonials(),
          _buildAIChat(),
          _buildFooter(key: _aboutKey),
        ],
      ),
    );
  }

  // ─── TOP BAR ─────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      color: AppTheme.primaryDark,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      child: Row(
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.flight, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Travixx',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Türkiye'yi Keşfet",
                    style: TextStyle(color: AppTheme.accent, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Nav links — tıklanınca ilgili bölüme kaydır
          _navLink(I18n.t('nav.features'), () => _scrollTo(_featuresKey)),
          _navLink(I18n.t('nav.howItWorks'), () => _scrollTo(_howWorksKey)),
          _navLink(I18n.t('nav.about'), () => _scrollTo(_aboutKey)),
          const SizedBox(width: 12),
          const LanguageSelector(dark: true),
          const SizedBox(width: 8),
          _navBtn(I18n.t('nav.login'), false, () {
            setState(() => _isLogin = true);
            _scrollToTop();
          }),
          const SizedBox(width: 8),
          _navBtn(I18n.t('nav.register'), true, () {
            setState(() => _isLogin = false);
            _scrollToTop();
          }),
        ],
      ),
    );
  }

  Widget _navLink(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.accent, fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _navBtn(String label, bool filled, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: filled
              ? const Color(0xFFF97316)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: filled
                ? const Color(0xFFF97316)
                : Colors.white.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ─── HERO SECTION ────────────────────────────────────────────
  Widget _buildHeroSection() {
    return SizedBox(
      height: 500,
      child: Row(
        children: [
          // Sol — fotoğraf + bilgi
          Expanded(
            flex: 11,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: _destinationVisual(_leftDest(), 'hero'),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryDark.withValues(alpha: 0.88),
                        AppTheme.primaryDark.withValues(alpha: 0.55),
                        AppTheme.primaryDark.withValues(alpha: 0.15),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF97316),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.white, size: 14),
                            const SizedBox(width: 5),
                            Text(
                              I18n.t('landing.badge'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.3,
                          ),
                          children: [
                            TextSpan(text: "Türkiye'yi\n"),
                            TextSpan(
                              text: 'Akıllıca ',
                              style: TextStyle(color: Color(0xFFFB923C)),
                            ),
                            TextSpan(text: 'Keşfet'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        '81 şehir, 2.400+ tarihi mekan. QR destekli\nrehberlik ve yapay zeka ile kişisel gezi deneyimi.',
                        style: TextStyle(
                          color: Color(0xFFCBD5E9),
                          fontSize: 15,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Stats
                      Row(
                        children: [
                          _statItem('81', I18n.t('landing.stat.city')),
                          const SizedBox(width: 32),
                          _statItem('2.4K+', I18n.t('landing.stat.place')),
                          const SizedBox(width: 32),
                          _statItem('6', I18n.t('landing.stat.lang')),
                          const SizedBox(width: 32),
                          _statItem('4.9★', I18n.t('landing.stat.rating')),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Tags
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _heroTag(Icons.qr_code_scanner, I18n.t('landing.tag.qr')),
                          _heroTag(Icons.gps_fixed, I18n.t('landing.tag.gps')),
                          _heroTag(Icons.language, I18n.t('landing.tag.lang')),
                          _heroTag(Icons.psychology, I18n.t('landing.tag.ai')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Sağ — giriş kartı
          Expanded(
            flex: 9,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.95),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=1600&q=80&auto=format&fit=crop',
                  ),
                  fit: BoxFit.cover,
                  opacity: 0.15,
                ),
              ),
              padding: const EdgeInsets.all(32),
              child: Center(child: _buildAuthCard()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String n, String l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          n,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(l, style: const TextStyle(color: Color(0xFF94A3C0), fontSize: 11)),
      ],
    );
  }

  Widget _heroTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFFB923C), size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: Color(0xFFE2E8F4), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ─── MOBILE HERO ─────────────────────────────────────────────
  Widget _buildMobileHero() {
    return Stack(
      children: [
        SizedBox(
          height: 280,
          width: double.infinity,
          child: _destinationVisual(_leftDest(), 'mhero'),
        ),
        Container(
          height: 280,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryDark.withValues(alpha: 0.85),
                AppTheme.primaryDark.withValues(alpha: 0.4),
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Türkiye'nin #1 Turizm Platformu",
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Türkiye'yi Akıllıca Keşfet",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '81 şehir · 2.400+ mekan · QR Rehber · 6 Dil',
                style: TextStyle(color: Color(0xFFCBD5E9), fontSize: 12),
              ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.flight,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Travixx',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const LanguageSelector(dark: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── AUTH CARD ───────────────────────────────────────────────
  Widget _buildAuthCard() {
    return Container(
      key: _authKey,
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: _isLogin ? _buildLoginForm() : _buildRegisterForm(),
      ),
    );
  }

  // ─── LOGIN FORM ──────────────────────────────────────────────
  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          I18n.t('auth.welcome'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          I18n.t('auth.signInPrompt'),
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 20),
        // Tab
        Container(
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          padding: const EdgeInsets.all(3),
          child: Row(
            children: [
              _authTab('Giriş Yap', true),
              _authTab(
                'Kayıt Ol',
                false,
                onTap: () => setState(() => _isLogin = false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _inputField(
          _loginEmailCtrl,
          I18n.t('auth.email'),
          Icons.email_outlined,
          type: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _inputField(_loginPassCtrl, I18n.t('auth.password'), Icons.lock_outline,
            obscure: true),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Beni hatırla
            GestureDetector(
              onTap: () => setState(() => _rememberMe = !_rememberMe),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (v) =>
                          setState(() => _rememberMe = v ?? true),
                      activeColor: const Color(0xFFF97316),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    I18n.t('auth.rememberMe'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Şifremi unuttum
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                I18n.t('auth.forgotPassword'),
                style: const TextStyle(color: Color(0xFFF97316), fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _submitBtn(I18n.t('nav.login'), Icons.login, () async {
          await _signIn(_loginEmailCtrl.text, _loginPassCtrl.text);
        }),
        const SizedBox(height: 16),
        _orDivider(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _socialBtn(
                'Google',
                Icons.g_mobiledata,
                const Color(0xFFEA4335),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _socialBtn('Apple', Icons.apple, Colors.black)),
          ],
        ),
        const SizedBox(height: 16),
        _orDivider(text: 'veya telefon ile'),
        const SizedBox(height: 16),
        _phoneSection(),
      ],
    );
  }

  // ─── REGISTER FORM ───────────────────────────────────────────
  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          I18n.t('auth.createAccount'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          I18n.t('auth.registerPrompt'),
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          padding: const EdgeInsets.all(3),
          child: Row(
            children: [
              _authTab(
                'Giriş Yap',
                false,
                onTap: () => setState(() => _isLogin = true),
              ),
              _authTab('Kayıt Ol', true),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _inputField(_regNameCtrl, I18n.t('auth.fullName'), Icons.person_outline),
        const SizedBox(height: 12),
        _inputField(
          _regEmailCtrl,
          I18n.t('auth.email'),
          Icons.email_outlined,
          type: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _inputField(
          _regPassCtrl,
          I18n.t('auth.passwordHint'),
          Icons.lock_outline,
          obscure: true,
        ),
        const SizedBox(height: 20),
        _submitBtn(I18n.t('nav.register'), Icons.person_add, () async {
          await _signUp(_regEmailCtrl.text, _regPassCtrl.text);
        }),
        const SizedBox(height: 16),
        _orDivider(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _socialBtn(
                'Google',
                Icons.g_mobiledata,
                const Color(0xFFEA4335),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _socialBtn('Apple', Icons.apple, Colors.black)),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Kayıt olarak Gizlilik Politikası ve Kullanım Şartlarını kabul etmiş olursunuz.',
          style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ─── FORM HELPERS ────────────────────────────────────────────
  Widget _authTab(String label, bool active, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: active ? Colors.white : AppTheme.textSecondary,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool obscure = false,
    TextInputType? type,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: type,
      style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 13,
          color: AppTheme.textSecondary,
        ),
        prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        filled: true,
        fillColor: AppTheme.background,
      ),
    );
  }

  Widget _submitBtn(String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF97316),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _orDivider({String text = 'veya şununla devam et'}) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AppTheme.cardBorder, thickness: 0.5),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ),
        const Expanded(
          child: Divider(color: AppTheme.cardBorder, thickness: 0.5),
        ),
      ],
    );
  }

  Widget _socialBtn(String label, IconData icon, Color color) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: color, size: 22),
      label: Text(
        label,
        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: const BorderSide(color: AppTheme.cardBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _phoneSection() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 68,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: const Text(
                '+90',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '5XX XXX XX XX',
                  hintStyle: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.cardBorder),
                  ),
                  filled: true,
                  fillColor: AppTheme.background,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(
              Icons.sms_outlined,
              size: 18,
              color: AppTheme.primary,
            ),
            label: const Text(
              'SMS Doğrulama Kodu Gönder',
              style: TextStyle(fontSize: 13, color: AppTheme.primary),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              side: const BorderSide(color: AppTheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── FEATURES SECTION ────────────────────────────────────────
  Widget _buildFeaturesSection({Key? key}) {
    final features = [
      {
        'icon': Icons.qr_code_scanner,
        'color': const Color(0xFFF97316),
        'bg': const Color(0xFFFFF7ED),
        'title': 'Akıllı QR Rehber',
        'desc':
            'Her tarihi mekanda QR kodu okutun, anında detaylı tarihçe ve bilgiye ulaşın.',
      },
      {
        'icon': Icons.gps_fixed,
        'color': AppTheme.primary,
        'bg': const Color(0xFFEFF6FF),
        'title': 'GPS Tabanlı Sıralama',
        'desc':
            'Konumunuza göre en yakın mekanlar otomatik üste listelenir, km ve süre gösterilir.',
      },
      {
        'icon': Icons.language,
        'color': const Color(0xFF854D0E),
        'bg': const Color(0xFFFEFCE8),
        'title': '6 Dil Desteği',
        'desc':
            'TR, EN, DE, AR, FR, RU dillerinde otomatik çeviri ile dil engeli ortadan kalkar.',
      },
      {
        'icon': Icons.psychology,
        'color': const Color(0xFFF97316),
        'bg': const Color(0xFFFFF7ED),
        'title': 'Yapay Zeka Asistanı',
        'desc':
            'Kişisel gezi planı oluşturun, öneriler alın ve sorularınızı AI\'a sorun.',
      },
      {
        'icon': Icons.devices,
        'color': AppTheme.primary,
        'bg': const Color(0xFFEFF6FF),
        'title': 'Web & Mobil',
        'desc':
            'Tek hesapla web ve mobil üzerinden kesintisiz erişim, her cihazda mükemmel görünüm.',
      },
      {
        'icon': Icons.favorite_outline,
        'color': const Color(0xFF854D0E),
        'bg': const Color(0xFFFEFCE8),
        'title': 'Favori & Rota Planla',
        'desc':
            'Mekanları favorileyin, kişisel gezi rotanızı oluşturun ve paylaşın.',
      },
    ];

    return Container(
      key: key,
      color: AppTheme.background,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        children: [
          _sectionBadge('Özellikler'),
          const SizedBox(height: 10),
          const Text(
            "Neden Travixx?",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Turizmi yeniden tanımlayan 6 güçlü özellik',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 36),
          LayoutBuilder(
            builder: (ctx, constraints) {
              final cols = constraints.maxWidth > 700 ? 3 : 2;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: features.map((f) {
                  return SizedBox(
                    width: (constraints.maxWidth - (cols - 1) * 16) / cols,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.cardBorder,
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: f['bg'] as Color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              f['icon'] as IconData,
                              color: f['color'] as Color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            f['title'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            f['desc'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── PHOTO STRIP — 5 sn'de bir otomatik değişen carousel ─────
  Widget _buildPhotoStrip() {
    return SizedBox(
      height: 240,
      child: Row(
        children: [
          Expanded(child: _destinationVisual(_leftDest(), 'left')),
          Expanded(child: _destinationVisual(_rightDest(), 'right')),
        ],
      ),
    );
  }

  /// Bir destinasyon için görsel widget'ı.
  /// Eğer 'url' varsa: Image.network + üstünde isim/altyazı katmanı.
  /// Eğer 'url' yoksa: özel gradient kartı + büyük emoji + isim/altyazı.
  Widget _destinationVisual(Map<String, dynamic> d, String prefix) {
    final url = d['url'] as String?;
    final colors = (d['colors'] as List).cast<Color>();
    final name = d['name'] as String;
    final sub = d['sub'] as String;
    final emoji = d['emoji'] as String;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        fit: StackFit.expand,
        children: [
          ...previousChildren,
          if (currentChild != null) currentChild,
        ],
      ),
      child: KeyedSubtree(
        key: ValueKey('${prefix}_$name'),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ARKAPLAN — foto varsa onu, yoksa gradient
            if (url != null)
              Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _gradientCard(colors, emoji),
                loadingBuilder: (_, child, prog) =>
                    prog == null ? child : _gradientCard(colors, emoji),
              )
            else
              _gradientCard(colors, emoji),

            // Karanlık alt gradient (yazıların okunması için)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),

            // Bilgi etiketi
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sub,
                          style: const TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontSize: 12,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Foto yoksa veya yüklenmediyse: tasarımlı gradient kart (büyük dekoratif emoji).
  Widget _gradientCard(List<Color> colors, String emoji) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Sağ üstte büyük dekoratif emoji (yarı saydam)
          Positioned(
            top: -20,
            right: -10,
            child: Opacity(
              opacity: 0.18,
              child: Text(emoji, style: const TextStyle(fontSize: 200)),
            ),
          ),
          // Ortada hafif yıldız dokusu (basit)
          Positioned(
            left: 30,
            top: 40,
            child: Text('✦',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.3))),
          ),
          Positioned(
            right: 80,
            top: 90,
            child: Text('✧',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.4))),
          ),
        ],
      ),
    );
  }

  // ─── HOW IT WORKS ────────────────────────────────────────────
  Widget _buildHowItWorks({Key? key}) {
    final steps = [
      {
        'n': '1',
        'title': 'Kayıt Ol',
        'desc':
            'E-posta, Google veya telefon ile saniyeler içinde ücretsiz hesap oluştur.',
      },
      {
        'n': '2',
        'title': 'Şehir Seç',
        'desc':
            '81 il arasından seç veya GPS ile konumuna en yakın mekanları bul.',
      },
      {
        'n': '3',
        'title': 'QR Okut & Keşfet',
        'desc':
            'Mekandaki QR kodu okut, kendi dilinde tarihçeyi oku ve rotanı planla.',
      },
    ];

    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      color: Colors.white,
      child: Column(
        children: [
          _sectionBadge('Nasıl Çalışır?'),
          const SizedBox(height: 10),
          const Text(
            '3 Adımda Keşfet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Dakikalar içinde gezmeye başla',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 40),
          Row(
            children: steps.asMap().entries.map((e) {
              final isLast = e.key == steps.length - 1;
              return Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF97316),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                e.value['n']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            e.value['title']!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            e.value['desc']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      const Padding(
                        padding: EdgeInsets.only(top: 14),
                        child: Icon(
                          Icons.arrow_forward,
                          color: Color(0xFFF97316),
                          size: 22,
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── TESTIMONIALS ────────────────────────────────────────────
  Widget _buildTestimonials() {
    final reviews = [
      {
        'stars': '★★★★★',
        'text':
            '"İstanbul\'u gezerken QR sistemi inanılmaz işe yaradı. Her mekanın hikayesini anında öğrendim."',
        'initials': 'AY',
        'name': 'Ayşe Y.',
        'loc': 'İstanbul',
        'color': const Color(0xFFF97316),
      },
      {
        'stars': '★★★★★',
        'text':
            '"Almanca dil desteği mükemmel. Türkiye\'yi gezerken hiç dil sorunu yaşamadım!"',
        'initials': 'HM',
        'name': 'Hans M.',
        'loc': 'Berlin, Almanya',
        'color': AppTheme.primary,
      },
      {
        'stars': '★★★★★',
        'text':
            '"GPS sıralaması sayesinde Kapadokya\'da en yakın mekanları önce gezdim. Harika!"',
        'initials': 'MK',
        'name': 'Mehmet K.',
        'loc': 'Ankara',
        'color': const Color(0xFF15803D),
      },
    ];

    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        children: [
          _sectionBadge('Kullanıcı Yorumları'),
          const SizedBox(height: 10),
          const Text(
            'Onlar Ne Dedi?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (ctx, constraints) {
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: reviews.map((r) {
                  return SizedBox(
                    width: constraints.maxWidth > 700
                        ? (constraints.maxWidth - 32) / 3
                        : constraints.maxWidth,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.cardBorder,
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r['stars'] as String,
                            style: const TextStyle(
                              color: Color(0xFFEAB308),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            r['text'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              height: 1.65,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: r['color'] as Color,
                                child: Text(
                                  r['initials'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r['name'] as String,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    r['loc'] as String,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── AI CHAT ─────────────────────────────────────────────────
  Widget _buildAIChat() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder, width: 0.5),
        color: Colors.white,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppTheme.primaryDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF97316),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Travixx AI Asistan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Gezi planınızda size yardımcı olmaya hazır',
                      style: TextStyle(color: AppTheme.accent, fontSize: 11),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Çevrimiçi',
                  style: TextStyle(color: Color(0xFF22C55E), fontSize: 11),
                ),
              ],
            ),
          ),
          // Messages
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _chatMsg(
                  'Merhaba! Ben Travixx AI asistanınım. Türkiye gezi planınızda size yardımcı olabilirim.',
                  false,
                ),
                const SizedBox(height: 8),
                _chatMsg("İstanbul'da 2 günlük rota önerir misin?", true),
                const SizedBox(height: 8),
                _chatMsg(
                  '1. gün: Tarihi Yarımada — Ayasofya, Topkapı Sarayı, Kapalıçarşı.\n2. gün: Boğaz turu, Galata Kulesi, Beşiktaş. Detaylı rota oluşturayım mı?',
                  false,
                ),
              ],
            ),
          ),
          // Chips
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  [
                        'Evet, rotayı oluştur',
                        'Müzeler',
                        'Restoranlar',
                        'Bütçe dostu',
                        'Aile gezisi',
                      ]
                      .map(
                        (t) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.cardBorder,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            t,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatMsg(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFFF97316) : AppTheme.background,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 14),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: isUser ? Colors.white : AppTheme.textPrimary,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  // ─── FOOTER ──────────────────────────────────────────────────
  Widget _buildFooter({Key? key}) {
    return Container(
      key: key,
      color: AppTheme.primaryDark,
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (ctx, constraints) {
              return Wrap(
                spacing: 40,
                runSpacing: 32,
                children: [
                  SizedBox(
                    width: constraints.maxWidth > 700
                        ? (constraints.maxWidth - 120) / 2
                        : constraints.maxWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF97316),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(
                                Icons.flight,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Travixx',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Türkiye'nin akıllı turizm platformu. 81 şehir, binlerce mekan, yapay zeka destekli rehberlik.",
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children:
                              [
                                    Icons.flutter_dash,
                                    Icons.camera_alt_outlined,
                                    Icons.work_outline,
                                    Icons.play_circle_outline,
                                  ]
                                  .map(
                                    (icon) => Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.07,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.1,
                                          ),
                                        ),
                                      ),
                                      child: Icon(
                                        icon,
                                        color: const Color(0xFF94A3C0),
                                        size: 18,
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ),
                  ),
                  ...[
                    {
                      'title': 'Ürün',
                      'links': [
                        'Özellikler',
                        'Nasıl Çalışır?',
                        'Fiyatlandırma',
                        'Güncellemeler',
                      ],
                    },
                    {
                      'title': 'Şirket',
                      'links': ['Hakkımızda', 'Blog', 'Kariyer', 'İletişim'],
                    },
                    {
                      'title': 'Destek',
                      'links': [
                        'Yardım Merkezi',
                        'Gizlilik Politikası',
                        'Kullanım Şartları',
                        'KVKK',
                      ],
                    },
                  ].map(
                    (col) => SizedBox(
                      width: 130,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            col['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...(col['links'] as List<String>).map(
                            (l) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                l,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          Container(height: 0.5, color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '© 2026 Travixx. Tüm hakları saklıdır.',
                style: TextStyle(color: Color(0xFF475569), fontSize: 12),
              ),
              Row(
                children: ['SSL Güvenli', 'KVKK Uyumlu', 'v1.0.0']
                    .map(
                      (t) => Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Text(
                          t,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── SECTION BADGE ───────────────────────────────────────────
  Widget _sectionBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFF97316),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ─── SUPABASE AUTH ───────────────────────────────────────────
  Future<void> _signIn(String email, String password) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      _showSnack('E-posta ve şifre boş olamaz', isError: true);
      return;
    }
    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );
      if (!mounted) return;
      if (res.session != null) {
        _showSnack('Hoş geldin! 👋', isError: false);
        context.go('/home');
      }
    } on AuthException catch (e) {
      if (mounted) _showSnack(e.message, isError: true);
    } catch (e) {
      if (mounted) _showSnack('Bir hata oluştu: $e', isError: true);
    }
  }

  Future<void> _signUp(String email, String password) async {
    if (email.trim().isEmpty || password.trim().length < 6) {
      _showSnack('Geçerli bir e-posta ve en az 6 karakter şifre girin',
          isError: true);
      return;
    }
    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: email.trim(),
        password: password.trim(),
      );
      if (!mounted) return;
      // Email confirmation kapalıysa session direkt gelir, açıksa null gelir
      if (res.session != null) {
        _showSnack('Hesap oluşturuldu, giriş yapılıyor...', isError: false);
        context.go('/home');
      } else {
        _showSnack(
          'Kayıt başarılı! E-posta kutunu kontrol et ve onaylama linkine tıkla.',
          isError: false,
        );
      }
    } on AuthException catch (e) {
      if (mounted) _showSnack(e.message, isError: true);
    } catch (e) {
      if (mounted) _showSnack('Bir hata oluştu: $e', isError: true);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
