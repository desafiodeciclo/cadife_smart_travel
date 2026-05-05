import 'dart:async';
import 'package:cadife_smart_travel/features/settings/domain/entities/user_preferences.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeRepository {
  final Isar? _isar;
  final SharedPreferences _prefs;
  
  // Controller para notificar mudanças no Web onde o Isar.watch não funciona
  static final _webThemeController = StreamController<ThemePreference>.broadcast();
  
  const ThemeRepository(this._isar, this._prefs);
  
  static const _themeKey = 'user_theme_preference';
  
  Future<ThemePreference> getThemePreference() async {
    if (_isar == null) {
      final index = _prefs.getInt(_themeKey);
      if (index == null) return ThemePreference.system;
      return ThemePreference.values[index];
    }
    
    final prefs = await _isar.userPreferencesIsars.get(1);
    
    if (prefs == null) {
      return ThemePreference.system;
    }
    
    return prefs.themePreference;
  }
  
  Future<void> setThemePreference(ThemePreference preference) async {
    if (_isar == null) {
      await _prefs.setInt(_themeKey, preference.index);
      _webThemeController.add(preference);
      return;
    }

    final isarModel = UserPreferencesIsar()
      ..themePreference = preference
      ..updatedAt = DateTime.now();
    
    await _isar.writeTxn(() async {
      await _isar.userPreferencesIsars.put(isarModel);
    });
  }
  
  Stream<ThemePreference> watchThemePreference() {
    if (_isar == null) {
      // Combina o valor inicial com as mudanças futuras do controller
      return _webThemeController.stream.asyncStartWith(getThemePreference);
    }

    return _isar.userPreferencesIsars
      .watchObject(1, fireImmediately: true)
      .map((prefs) {
        if (prefs == null) return ThemePreference.system;
        return prefs.themePreference;
      });
  }
}

extension _StreamExtension<T> on Stream<T> {
  Stream<T> asyncStartWith(Future<T> Function() initial) async* {
    yield await initial();
    yield* this;
  }
}
