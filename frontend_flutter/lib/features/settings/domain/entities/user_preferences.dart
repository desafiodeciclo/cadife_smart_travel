import 'package:isar/isar.dart';

part 'user_preferences.g.dart';

@Collection()
class UserPreferencesIsar {
  Id id = 1; // Apenas um registro de preferências
  
  @enumerated
  ThemePreference themePreference = ThemePreference.system; // light, dark, system
  
  DateTime updatedAt = DateTime.now();
  
  UserPreferencesIsar();
}


enum ThemePreference {
  light,
  dark,
  system,
}
