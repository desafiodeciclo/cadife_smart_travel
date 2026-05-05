import 'package:isar/isar.dart';
import 'package:cadife_smart_travel/features/settings/domain/entities/user_preferences.dart';

class ThemeRepository {
  final Isar _isar;
  
  const ThemeRepository(this._isar);
  
  Future<ThemePreference> getThemePreference() async {
    final prefs = await _isar.userPreferencesIsars.get(1);
    
    if (prefs == null) {
      // Primeira instalação: respeita sistema
      return ThemePreference.system;
    }
    
    return prefs.themePreference;
  }
  
  Future<void> setThemePreference(ThemePreference preference) async {
    final isarModel = UserPreferencesIsar()
      ..themePreference = preference
      ..updatedAt = DateTime.now();
    
    await _isar.writeTxn(() async {
      await _isar.userPreferencesIsars.put(isarModel);
    });
  }
  
  Stream<ThemePreference> watchThemePreference() {
    return _isar.userPreferencesIsars
      .watchObject(1, fireImmediately: true)
      .map((prefs) {
        if (prefs == null) return ThemePreference.system;
        return prefs.themePreference;
      });
  }
}
