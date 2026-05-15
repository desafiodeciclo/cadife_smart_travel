import 'package:cadife_smart_travel/core/services/secure_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Script de migração: transfere dados de perfil de SharedPreferences → SecureStorage.
///
/// Executado uma única vez ao iniciar o app. Dados antigos são deletados de
/// SharedPreferences após migração bem-sucedida.
class ProfileMigrationManager {
  static const String _migrationFlagKey = 'profile_migrated_to_secure_v1';

  final SecureStorageService _secureStorage;

  ProfileMigrationManager({required SecureStorageService secureStorage})
      : _secureStorage = secureStorage;

  /// Executa migração se ainda não foi feita. Retorna true se migrou, false caso contrário.
  Future<bool> runMigration() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final alreadyMigrated = prefs.getBool(_migrationFlagKey) ?? false;
      if (alreadyMigrated) {
        return false;
      }

      // Migrate profile data (JSON completo)
      final profileJson = prefs.getString('consultant_profile_v1');
      if (profileJson != null) {
        await _secureStorage.write(
          key: 'consultant_profile_v1',
          value: profileJson,
        );
        await prefs.remove('consultant_profile_v1');
      }

      // Mark migration as complete
      await prefs.setBool(_migrationFlagKey, true);

      return true;
    } on Exception catch (_) {
      // Erro na migração — deixar app rodar mesmo se falhar
      return false;
    }
  }
}
