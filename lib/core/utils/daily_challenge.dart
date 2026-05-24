/// Günün tarihine göre rotasyonlu görev döndürür.
/// Aynı gün her zaman aynı görev gösterilir (deterministic).
class DailyChallenge {
  static const _challenges = [
    _Challenge(
      emoji: '🏛️',
      titleKey: 'challenge.museum',
      descKey: 'challenge.museumDesc',
      category: 'Müze',
    ),
    _Challenge(
      emoji: '⛰️',
      titleKey: 'challenge.nature',
      descKey: 'challenge.natureDesc',
      category: 'Doğa',
    ),
    _Challenge(
      emoji: '🕌',
      titleKey: 'challenge.religious',
      descKey: 'challenge.religiousDesc',
      category: 'Dini',
    ),
    _Challenge(
      emoji: '🗿',
      titleKey: 'challenge.historic',
      descKey: 'challenge.historicDesc',
      category: 'Tarihi',
    ),
    _Challenge(
      emoji: '🎨',
      titleKey: 'challenge.culture',
      descKey: 'challenge.cultureDesc',
      category: 'Kültür',
    ),
    _Challenge(
      emoji: '🌅',
      titleKey: 'challenge.scenic',
      descKey: 'challenge.scenicDesc',
      category: 'Manzara',
    ),
    _Challenge(
      emoji: '✨',
      titleKey: 'challenge.featured',
      descKey: 'challenge.featuredDesc',
      category: '',
    ),
  ];

  /// Bugünün görevi (yıl gününe göre)
  static DailyChallengeItem today() {
    final day = DateTime.now().difference(DateTime(2025, 1, 1)).inDays;
    final c = _challenges[day.abs() % _challenges.length];
    return DailyChallengeItem(
      emoji: c.emoji,
      titleKey: c.titleKey,
      descKey: c.descKey,
      category: c.category,
    );
  }
}

class _Challenge {
  final String emoji;
  final String titleKey;
  final String descKey;
  final String category;
  const _Challenge({
    required this.emoji,
    required this.titleKey,
    required this.descKey,
    required this.category,
  });
}

class DailyChallengeItem {
  final String emoji;
  final String titleKey;
  final String descKey;
  final String category;
  const DailyChallengeItem({
    required this.emoji,
    required this.titleKey,
    required this.descKey,
    required this.category,
  });
}
