import 'package:supabase_flutter/supabase_flutter.dart';

/// Ziyaretçilerin bildirdiği fiyatlar (place_prices tablosu).
///
/// Beach club şezlongu, kokteyl, giriş ücreti gibi fiyatlar için ücretsiz ve
/// yasal bir kaynak olmadığından fiyatlar kullanıcılardan toplanır; ekranda
/// son 180 günün ortancası (place_price_summary görünümü) gösterilir.
class PriceService {
  static final _supabase = Supabase.instance.client;

  /// Bildirilebilen kalemler (veritabanı kısıtıyla aynı sırada).
  static const items = [
    'entry',
    'sunbed',
    'cocktail',
    'beer',
    'soft_drink',
    'water',
    'coffee',
    'main_dish',
    'other',
  ];

  static const currencies = ['TRY', 'EUR', 'USD', 'GBP'];

  static Future<List<PriceSummary>> summary(String placeId) async {
    try {
      final rows = await _supabase
          .from('place_price_summary')
          .select()
          .eq('place_id', placeId);
      final list = (rows as List)
          .map((r) => PriceSummary.fromJson(r as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => items.indexOf(a.item).compareTo(items.indexOf(b.item)));
      return list;
    } catch (_) {
      return const [];
    }
  }

  /// Birden çok mekanın özetleri (liste ekranı için tek istek).
  static Future<Map<String, List<PriceSummary>>> summaries(
      List<String> placeIds) async {
    if (placeIds.isEmpty) return const {};
    try {
      final rows = await _supabase
          .from('place_price_summary')
          .select()
          .inFilter('place_id', placeIds);
      final out = <String, List<PriceSummary>>{};
      for (final r in rows as List) {
        final s = PriceSummary.fromJson(r as Map<String, dynamic>);
        out.putIfAbsent(s.placeId, () => []).add(s);
      }
      return out;
    } catch (_) {
      return const {};
    }
  }

  /// Son bildirimler (yeniden eskiye).
  static Future<List<PriceReport>> recent(String placeId, {int limit = 20}) async {
    try {
      final rows = await _supabase
          .from('place_prices')
          .select()
          .eq('place_id', placeId)
          .order('observed_on', ascending: false)
          .order('created_at', ascending: false)
          .limit(limit);
      return (rows as List)
          .map((r) => PriceReport.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Fiyat bildirir. Hata olursa açıklayıcı bir kod döner, başarıda null.
  static Future<String?> report({
    required String placeId,
    required String item,
    required double amount,
    String currency = 'TRY',
    String? label,
    String? note,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 'login';
    if (!items.contains(item) || !currencies.contains(currency)) return 'invalid';
    if (amount <= 0 || amount >= 1000000) return 'invalid';
    try {
      await _supabase.from('place_prices').insert({
        'place_id': placeId,
        'user_id': user.id,
        'item': item,
        'amount': amount,
        'currency': currency,
        if (label != null && label.trim().isNotEmpty)
          'label': label.trim().substring(0, label.trim().length.clamp(0, 60)),
        if (note != null && note.trim().isNotEmpty)
          'note': note.trim().substring(0, note.trim().length.clamp(0, 200)),
      });
      return null;
    } on PostgrestException catch (e) {
      // 23505: aynı gün aynı kalem zaten bildirilmiş
      return e.code == '23505' ? 'duplicate' : 'failed';
    } catch (_) {
      return 'failed';
    }
  }

  static Future<bool> delete(String reportId) async {
    try {
      await _supabase.from('place_prices').delete().eq('id', reportId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// "₺750", "€20" gibi kısa gösterim.
  static String format(double amount, String currency) {
    const symbols = {'TRY': '₺', 'EUR': '€', 'USD': r'$', 'GBP': '£'};
    final whole = amount == amount.roundToDouble();
    final n = whole ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);
    return '${symbols[currency] ?? '$currency '}$n';
  }
}

class PriceSummary {
  final String placeId;
  final String item;
  final String currency;
  final double median;
  final double low;
  final double high;
  final int reports;
  final DateTime? lastSeen;

  const PriceSummary({
    required this.placeId,
    required this.item,
    required this.currency,
    required this.median,
    required this.low,
    required this.high,
    required this.reports,
    this.lastSeen,
  });

  factory PriceSummary.fromJson(Map<String, dynamic> j) => PriceSummary(
        placeId: j['place_id'] as String,
        item: j['item'] as String,
        currency: j['currency'] as String? ?? 'TRY',
        median: _num(j['median']),
        low: _num(j['low']),
        high: _num(j['high']),
        reports: _num(j['reports']).toInt(),
        lastSeen: DateTime.tryParse(j['last_seen']?.toString() ?? ''),
      );
}

class PriceReport {
  final String id;
  final String userId;
  final String item;
  final String? label;
  final double amount;
  final String currency;
  final String? note;
  final DateTime observedOn;

  const PriceReport({
    required this.id,
    required this.userId,
    required this.item,
    this.label,
    required this.amount,
    required this.currency,
    this.note,
    required this.observedOn,
  });

  factory PriceReport.fromJson(Map<String, dynamic> j) => PriceReport(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        item: j['item'] as String,
        label: j['label'] as String?,
        amount: _num(j['amount']),
        currency: j['currency'] as String? ?? 'TRY',
        note: j['note'] as String?,
        observedOn:
            DateTime.tryParse(j['observed_on']?.toString() ?? '') ?? DateTime.now(),
      );
}

/// PostgREST numeric değerleri sayı ya da metin olarak dönebilir.
double _num(Object? v) =>
    v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;
