import 'package:cadife_smart_travel/features/settings/application/theme_notifier.dart';
import 'package:cadife_smart_travel/features/settings/domain/entities/user_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockThemeNotifier extends ThemeNotifier {
  ThemePreference _current = ThemePreference.light;

  @override
  Stream<ThemePreference> build() {
    return Stream.value(_current);
  }

  @override
  Future<void> setTheme(ThemePreference preference) async {
    _current = preference;
    ref.invalidateSelf();
  }
}

void main() {
  testWidgets('Theme switch deve disparar alteração de estado no Riverpod', (tester) async {
    final container = ProviderContainer(
      overrides: [
        themeNotifierProvider.overrideWith(_MockThemeNotifier.new),
      ],
    );
    addTearDown(container.dispose);
    
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                final pref = ref.watch(themeNotifierProvider).valueOrNull ?? ThemePreference.light;
                return Switch(
                  key: const Key('theme_switch'),
                  value: pref == ThemePreference.dark,
                  onChanged: (isDark) {
                    ref.read(themeNotifierProvider.notifier).setTheme(
                      isDark ? ThemePreference.dark : ThemePreference.light,
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    // 1. Check initial state
    expect(container.read(themeNotifierProvider).value, ThemePreference.light);

    // 2. Tap to toggle
    final switchFinder = find.byKey(const Key('theme_switch'));
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    // 3. Assert
    expect(container.read(themeNotifierProvider).value, ThemePreference.dark);
  });
}
