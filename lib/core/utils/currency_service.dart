import 'dart:convert';
import 'package:http/http.dart' as http;

/// Para birimi çevirici (Frankfurter.app — ücretsiz, key gerektirmiyor).
/// Sadece TL → EUR/USD çevirisi için.
class CurrencyService {
  static double? _eurRate; // 1 TRY = ? EUR
  static double? _usdRate;
  static DateTime? _fetchedAt;

  static const _ttl = Duration(hours: 6); // 6 saatlik cache

  /// Cache var ve taze mi?
  static bool get _isStale {
    if (_fetchedAt == null) return true;
    return DateTime.now().difference(_fetchedAt!) > _ttl;
  }

  /// Kur verilerini çek (cache'lenir)
  static Future<void> _fetchRates() async {
    if (!_isStale) return;
    try {
      final response = await http
          .get(Uri.parse('https://api.frankfurter.app/latest?from=TRY&to=EUR,USD'))
          .timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rates = data['rates'] as Map<String, dynamic>?;
      if (rates == null) return;
      _eurRate = (rates['EUR'] as num?)?.toDouble();
      _usdRate = (rates['USD'] as num?)?.toDouble();
      _fetchedAt = DateTime.now();
    } catch (_) {}
  }

  /// Bir metindeki ilk sayı + TL'yi parse et: "50 TL", "100-200 TL"
  static double? extractTRYAmount(String text) {
    final match = RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:TL|tl|₺)').firstMatch(text);
    if (match == null) return null;
    final raw = match.group(1)!.replaceAll(',', '.');
    return double.tryParse(raw);
  }

  /// TRY tutarını EUR ve USD karşılığıyla döner.
  /// Örn: 100 TL → {eur: 2.85, usd: 3.10}
  static Future<({double? eur, double? usd})> convertFromTry(double try_) async {
    await _fetchRates();
    return (
      eur: _eurRate != null ? try_ * _eurRate! : null,
      usd: _usdRate != null ? try_ * _usdRate! : null,
    );
  }

  /// "100 TL" → "100 TL · ≈ 2.85 EUR · 3.10 USD" formatında string
  static Future<String> formatWithConversion(String original) async {
    final amount = extractTRYAmount(original);
    if (amount == null) return original;
    final c = await convertFromTry(amount);
    final parts = <String>[original];
    if (c.eur != null) parts.add('≈ ${c.eur!.toStringAsFixed(2)} EUR');
    if (c.usd != null) parts.add('≈ ${c.usd!.toStringAsFixed(2)} USD');
    return parts.join(' · ');
  }
}
