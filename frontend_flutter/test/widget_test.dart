import 'package:cadife_smart_travel/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App loads without crash', (tester) async {
    await tester.pumpWidget(const CadifeApp());
    expect(find.text('Cadife Smart Travel — Carregando...'), findsOneWidget);
  });
}
