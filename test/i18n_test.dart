import 'package:flutter_test/flutter_test.dart';
import 'package:travixx/core/i18n/i18n.dart';

void main() {
  final tr = I18n.all['tr']!;
  final placeholder = RegExp(r'\{(\w+)\}');
  Set<String> params(String s) =>
      placeholder.allMatches(s).map((m) => m.group(1)!).toSet();

  for (final lang in I18n.languages.map((l) => l.code)) {
    test('$lang: TR ile aynı anahtarlar', () {
      final map = I18n.all[lang]!;
      final missing = tr.keys.where((k) => !map.containsKey(k)).toList();
      final extra = map.keys.where((k) => !tr.containsKey(k)).toList();
      expect(missing, isEmpty, reason: 'eksik: ${missing.take(20)}');
      expect(extra, isEmpty, reason: 'fazla: ${extra.take(20)}');
    });

    test('$lang: yer tutucular ({name} vb.) TR ile aynı', () {
      final map = I18n.all[lang]!;
      final bad = [
        for (final k in tr.keys)
          if (map.containsKey(k) &&
              !setEquals(params(tr[k]!), params(map[k]!)))
            k,
      ];
      expect(bad, isEmpty, reason: bad.take(20).join(', '));
    });
  }
}

bool setEquals(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);
