import 'package:supabase_flutter/supabase_flutter.dart';

import '../i18n/i18n.dart';

/// Gemini sohbet servisi.
///
/// API anahtarı uygulamada TUTULMAZ. İstekler Supabase Edge Function
/// `gemini-chat` üzerinden gider; anahtar orada secret olarak durur
/// (bkz. supabase/functions/gemini-chat/index.ts).
class GeminiService {
  static const _function = 'gemini-chat';

  /// Kullanıcının gezi sorgusuna seçili dilde kısa bir giriş metni üretir.
  static Future<String?> generateTripIntro({
    required String cityName,
    required int days,
    required List<String> placeNames,
  }) {
    return _invoke({
      'mode': 'intro',
      'cityName': cityName,
      'days': days,
      'placeNames': placeNames.take(6).toList(),
      'lang': I18n.language.value,
    });
  }

  /// Genel sohbet. [history] önceki mesajlar (eskiden yeniye),
  /// role: 'user' veya 'model'.
  static Future<String?> chat(
    String userMessage, {
    List<({String role, String text})> history = const [],
  }) {
    return _invoke({
      'mode': 'chat',
      'message': userMessage,
      'lang': I18n.language.value,
      'history': [
        for (final h in history) {'role': h.role, 'text': h.text},
      ],
    });
  }

  static Future<String?> _invoke(Map<String, dynamic> body) async {
    try {
      final res = await Supabase.instance.client.functions
          .invoke(_function, body: body)
          .timeout(const Duration(seconds: 20));
      final data = res.data;
      if (data is Map && data['text'] is String) {
        final text = (data['text'] as String).trim();
        return text.isEmpty ? null : text;
      }
    } catch (_) {}
    return null;
  }
}
