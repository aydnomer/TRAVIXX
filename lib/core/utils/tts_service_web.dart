import 'package:web/web.dart' as web;

const _langMap = {
  'tr': 'tr-TR',
  'en': 'en-US',
  'de': 'de-DE',
  'ar': 'ar-SA',
  'fr': 'fr-FR',
  'ru': 'ru-RU',
};

void ttsSpeak(String text, String langCode) {
  try {
    ttsStop();
    final utterance = web.SpeechSynthesisUtterance(text);
    utterance.lang = _langMap[langCode] ?? 'tr-TR';
    utterance.rate = 0.95;
    utterance.pitch = 1.0;
    utterance.volume = 1.0;
    web.window.speechSynthesis.speak(utterance);
  } catch (_) {}
}

void ttsStop() {
  try {
    web.window.speechSynthesis.cancel();
  } catch (_) {}
}

bool ttsIsSpeaking() {
  try {
    return web.window.speechSynthesis.speaking;
  } catch (_) {
    return false;
  }
}
