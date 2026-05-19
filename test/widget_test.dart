// Basit smoke test — Travixx uygulamasının temel widget'larının
// yüklenebildiğini doğrular. Detaylı testler ileride eklenecek.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test — MaterialApp builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Travixx'))),
    );
    expect(find.text('Travixx'), findsOneWidget);
  });
}
