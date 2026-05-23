import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Sosyal paylaşım yardımcısı.
/// - URL'yi panoya kopyalar (her platformda çalışır)
/// - WhatsApp, Twitter, Facebook gibi direkt paylaşım linkleri üretir
class ShareService {
  /// URL'yi panoya kopyala. Başarılıysa true.
  static Future<bool> copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// WhatsApp paylaşım linki aç
  static Future<void> shareToWhatsApp(String text) async {
    final url = 'https://wa.me/?text=${Uri.encodeComponent(text)}';
    await _open(url);
  }

  /// Twitter (X) paylaşım linki aç
  static Future<void> shareToTwitter(String text, {String? url}) async {
    final params = <String, String>{'text': text};
    if (url != null) params['url'] = url;
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    await _open('https://twitter.com/intent/tweet?$query');
  }

  /// Facebook paylaşım linki aç
  static Future<void> shareToFacebook(String url) async {
    await _open(
      'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(url)}',
    );
  }

  /// E-posta paylaşımı (mailto:)
  static Future<void> shareViaEmail({
    required String subject,
    required String body,
  }) async {
    final url = Uri(
      scheme: 'mailto',
      query: 'subject=${Uri.encodeComponent(subject)}'
          '&body=${Uri.encodeComponent(body)}',
    ).toString();
    await _open(url);
  }

  static Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}
