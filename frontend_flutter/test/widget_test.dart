import 'package:cadife_smart_travel/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App loads without crash', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CadifeApp(),
        ),
      ),
    );
    // Verifica que o widget raiz foi montado sem exceções.
    expect(find.byType(CadifeApp), findsOneWidget);
  });
}
