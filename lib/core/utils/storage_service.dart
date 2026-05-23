import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Storage'a foto yükleme servisi.
///
/// Kullanım:
///   final url = await StorageService.pickAndUploadImage();
///   if (url != null) // başarılı, URL'i kaydet
///
/// Supabase'de 'travixx-uploads' bucket'i oluşturulmuş olmalı (public read).
class StorageService {
  static const _bucket = 'travixx-uploads';
  static final _picker = ImagePicker();

  /// Galeriden bir foto seç ve Supabase Storage'a yükle.
  /// Başarılı olursa public URL döner.
  static Future<String?> pickAndUploadImage({
    String folder = 'general',
    int maxWidth = 1280,
    int imageQuality = 80,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    try {
      // 1. Galeriden seç (web + mobil çalışır)
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth.toDouble(),
        imageQuality: imageQuality,
      );
      if (picked == null) return null;

      // 2. Bytes'a oku
      final Uint8List bytes = await picked.readAsBytes();

      // 3. Path oluştur (kullanıcı klasörü altında zaman damgalı)
      final ts = DateTime.now().millisecondsSinceEpoch;
      final ext = picked.name.contains('.')
          ? picked.name.split('.').last.toLowerCase()
          : 'jpg';
      final path = '${user.id}/$folder/$ts.$ext';

      // 4. Yükle
      await Supabase.instance.client.storage.from(_bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: _mimeFromExt(ext),
              upsert: false,
            ),
          );

      // 5. Public URL al
      final url = Supabase.instance.client.storage
          .from(_bucket)
          .getPublicUrl(path);
      return url;
    } catch (_) {
      return null;
    }
  }

  /// Yüklenen dosyayı sil (path bucket içindeki tam yol).
  static Future<bool> delete(String path) async {
    try {
      await Supabase.instance.client.storage.from(_bucket).remove([path]);
      return true;
    } catch (_) {
      return false;
    }
  }

  static String _mimeFromExt(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }
}
