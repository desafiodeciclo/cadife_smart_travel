import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cadife_smart_travel/config/providers/isar_provider.dart';
import 'package:cadife_smart_travel/features/settings/domain/entities/user_preferences.dart';
import 'package:cadife_smart_travel/features/settings/infrastructure/theme_repository.dart';

class ThemeNotifier extends StreamNotifier<ThemePreference> {
  @override
  Stream<ThemePreference> build() {
    final repo = ref.watch(themeRepositoryProvider);
    return repo.watchThemePreference();
  }
  
  Future<void> setTheme(ThemePreference preference) async {
    final repo = ref.watch(themeRepositoryProvider);
    await repo.setThemePreference(preference);
  }
  
  Future<void> toggleDarkMode(BuildContext context) async {
    final current = state.maybeWhen(
      data: (pref) => pref,
      orElse: () => ThemePreference.system,
    );
    
    // Se estiver no sistema, o toggle deve levar para o oposto do brilho atual do sistema
    ThemePreference newPref;
    if (current == ThemePreference.system) {
      final brightness = MediaQuery.platformBrightnessOf(context);
      newPref = brightness == Brightness.dark ? ThemePreference.light : ThemePreference.dark;
    } else {
      newPref = current == ThemePreference.dark ? ThemePreference.light : ThemePreference.dark;
    }
    
    await setTheme(newPref);
  }
}

// Providers
final themeRepositoryProvider = Provider<ThemeRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return ThemeRepository(isar);
});

final themeNotifierProvider =
    StreamNotifierProvider<ThemeNotifier, ThemePreference>(
      ThemeNotifier.new,
    );

// Helper para WidgetRef
extension ThemeRef on WidgetRef {
  ThemePreference get currentTheme {
    return watch(themeNotifierProvider).maybeWhen(
      data: (theme) => theme,
      orElse: () => ThemePreference.system,
    );
  }
  
  Future<void> setTheme(ThemePreference theme) {
    return read(themeNotifierProvider.notifier).setTheme(theme);
  }
  
  Future<void> toggleDarkMode(BuildContext context) {
    return read(themeNotifierProvider.notifier).toggleDarkMode(context);
  }
}
