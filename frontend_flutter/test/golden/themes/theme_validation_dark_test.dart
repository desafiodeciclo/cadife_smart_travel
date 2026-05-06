import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/settings/domain/entities/user_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/pump_app.dart';

void main() {
  group('Golden Test - Dark Theme Validation', () {
    testWidgets('Deve renderizar CadifeAppBar corretamente no dark mode', (tester) async {
      await pumpApp(
        tester,
        const Scaffold(
          appBar: CadifeAppBar(title: 'Dark Theme Test'),
          body: Center(child: Text('Content')),
        ),
        themePreference: ThemePreference.dark,
      );
      
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/dark_app_bar.png'),
      );
    });

    testWidgets('Deve renderizar CadifeButton primário no dark mode', (tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: Center(
            child: CadifeButton(
              text: 'Botão Primário',
              onPressed: () {},
            ),
          ),
        ),
        themePreference: ThemePreference.dark,
      );
      
      await expectLater(
        find.byType(CadifeButton),
        matchesGoldenFile('goldens/dark_button_primary.png'),
      );
    });
  });
}
