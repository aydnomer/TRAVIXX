import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import: web'de gerçek implementasyon, diğerlerinde stub
import 'tts_service_stub.dart'
    if (dart.library.js_interop) 'tts_service_web.dart' as _impl;

/// Web Speech API ile sesli okuma (Text-to-Speech).
/// Sadece web'de çalışır, mobil için flutter_tts paketi eklenebilir.
class TtsService {
  static void speak(String text, {String langCode = 'tr'}) {
    if (!kIsWeb) return;
    if (text.trim().isEmpty) return;
    _impl.ttsSpeak(text, langCode);
  }

  static void stop() {
    if (!kIsWeb) return;
    _impl.ttsStop();
  }

  static bool isSpeaking() {
    if (!kIsWeb) return false;
    return _impl.ttsIsSpeaking();
  }
}
