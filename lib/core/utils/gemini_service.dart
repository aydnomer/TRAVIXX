import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static const _model = 'gemini-2.0-flash';
  static const _url =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  /// Kullanıcının gezi sorgusuna Türkçe giriş metni üretir.
  /// Örnek: "İstanbul'da 2 günlük tarihi bir rota hazırladım..."
  static Future<String?> generateTripIntro({
    required String cityName,
    required int days,
    required List<String> placeNames,
  }) async {
    final places = placeNames.take(6).join(', ');
    final prompt = '''
Sen Travixx adlı bir Türkiye turizm uygulamasının yapay zeka asistanısın.
Kullanıcı $cityName için $days günlük bir gezi planı istedi.
Önerilen mekanlar: $places

Kısa, samimi ve heyecanlı bir Türkçe giriş metni yaz (2-3 cümle).
Şehrin en önemli özelliğinden bahset. Emoji kullan. Rota listesini tekrar yazma.
''';

    try {
      final response = await http.post(
        Uri.parse('$_url?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.8,
            'maxOutputTokens': 200,
          },
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates']?[0]?['content']?['parts']?[0]?['text']
            as String?;
      }
    } catch (_) {}
    return null;
  }

  /// Genel sohbet — kullanıcı herhangi bir soru sorabilir
  static Future<String?> chat(String userMessage) async {
    final prompt = '''
Sen Travixx adlı Türkiye turizm uygulamasının yapay zeka asistanısın.
Türkiye'deki şehirler, tarihi mekanlar, müzeler ve gezilecek yerler hakkında yardımcı olursun.
Kısa, samimi ve yardımsever cevaplar ver. Türkçe konuş.

Kullanıcı: $userMessage
''';

    try {
      final response = await http.post(
        Uri.parse('$_url?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.9,
            'maxOutputTokens': 400,
          },
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates']?[0]?['content']?['parts']?[0]?['text']
            as String?;
      }
    } catch (_) {}
    return null;
  }
}
