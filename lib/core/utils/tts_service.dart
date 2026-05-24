import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web/web.dart' as web;

/// Web Speech API ile sesli okuma (Text-to-Speech).
/// Sadece web'de çalışır, mobil için flutter_tts paketi eklenebilir.
class TtsService {
  /// Verilen metni mevcut dilde sesli oku.
  /// langCode: 'tr', 'en', 'de', 'ar', 'fr', 'ru'
  static void speak(String text, {String langCode = 'tr'}) {
    if (!kIsWeb) return;
    if (text.trim().isEmpty) return;
    try {
      _stop();
      final utterance = web.SpeechSynthesisUtterance(text);
      utterance.lang = _langMap[langCode] ?? 'tr-TR';
      utterance.rate = 0.95;
      utterance.pitch = 1.0;
      utterance.volume = 1.0;
      web.window.speechSynthesis.speak(utterance);
    } catch (_) {}
  }

  /// Konuşmayı durdur
  static void stop() => _stop();

  /// Şu an konuşuyor mu?
  static bool isSpeaking() {
    if (!kIsWeb) return false;
    try {
      return web.window.speechSynthesis.speaking;
    } catch (_) {
      return false;
    }
  }

  static void _stop() {
    try {
      web.window.speechSynthesis.cancel();
    } catch (_) {}
  }

  static const _langMap = {
    'tr': 'tr-TR',
    'en': 'en-US',
    'de': 'de-DE',
    'ar': 'ar-SA',
    'fr': 'fr-FR',
    'ru': 'ru-RU',
  };
}
