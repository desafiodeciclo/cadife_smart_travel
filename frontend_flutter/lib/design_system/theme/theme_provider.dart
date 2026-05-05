import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system);

  void setSystem() => state = ThemeMode.system;
  void setLight()  => state = ThemeMode.light;
  void setDark()   => state = ThemeMode.dark;

  void toggle() {
    state = switch (state) {
      ThemeMode.light  => ThemeMode.dark,
      ThemeMode.dark   => ThemeMode.light,
      ThemeMode.system => ThemeMode.dark,
    };
  }
}
