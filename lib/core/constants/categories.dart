/// Mekan kategorileri — tek kaynak.
///
/// Veritabanındaki eski kayıtlar Türkçe karaktersiz yazılmış olabilir
/// ("Doga", "Muze", "Kultur", "Alisveris"). Uygulama içinde her zaman
/// [normalize] edilmiş, doğru yazımlı ad kullanılır; böylece filtreler,
/// rozetler ve ruh hâli araması veritabanının yazımından bağımsız çalışır.
class Categories {
  Categories._();

  static const String historic = 'Tarihi';
  static const String museum = 'Müze';
  static const String nature = 'Doğa';
  static const String culture = 'Kültür';
  static const String scenic = 'Manzara';
  static const String shopping = 'Alışveriş';
  static const String religious = 'Dini';
  static const String beach = 'Plaj';

  /// Bilinen tüm kategoriler (mekan öner formu vb. için).
  static const List<String> all = [
    historic,
    museum,
    nature,
    culture,
    scenic,
    shopping,
    religious,
    beach,
  ];

  /// Karaktersiz/küçük harf karşılıkları → doğru yazım.
  static final Map<String, String> _byFolded = {
    for (final c in all) fold(c): c,
  };

  /// DB'den gelen kategori adını doğru yazıma çevirir.
  /// Bilinmeyen kategori olduğu gibi döner.
  static String normalize(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return value;
    return _byFolded[fold(value)] ?? value;
  }

  /// Türkçe karakterleri ASCII'ye indirger ve küçük harfe çevirir.
  /// Karşılaştırma ve arama için kullanılır ("Müzesi" → "muzesi").
  ///
  /// Not: 'İ'.toLowerCase() web'de (JS) "i̇" (2 karakter) döner; bu yüzden
  /// büyük harfler küçültülmeden önce elle eşlenir.
  static String fold(String s) {
    const map = {
      'İ': 'i', 'I': 'i', 'ı': 'i', 'Ş': 's', 'ş': 's', 'Ğ': 'g', 'ğ': 'g',
      'Ü': 'u', 'ü': 'u', 'Ö': 'o', 'ö': 'o', 'Ç': 'c', 'ç': 'c',
      'Â': 'a', 'â': 'a', 'Î': 'i', 'î': 'i', 'Û': 'u', 'û': 'u',
    };
    final sb = StringBuffer();
    for (final rune in s.runes) {
      final ch = String.fromCharCode(rune);
      sb.write(map[ch] ?? ch.toLowerCase());
    }
    return sb.toString();
  }

  /// [text] içinde [keywords]'den biri geçiyor mu (karaktersiz karşılaştırma).
  static bool containsAny(String text, Iterable<String> keywords) {
    final t = fold(text);
    return keywords.any((k) => t.contains(fold(k)));
  }
}
