/// Constantes gerais da aplicação.
class AppConstants {
  AppConstants._();

  // ── Timeouts ───────────────────────────────────────────
  static const int connectTimeout = 15000; // ms
  static const int receiveTimeout = 15000; // ms
  static const int offlineCacheExpiryMinutes = 30;

  // ── Hive Boxes ─────────────────────────────────────────
  static const String hiveBoxConfig = 'config';
  static const String hiveBoxCache = 'api_cache';
  static const String hiveBoxUser = 'user_prefs';

  // ── Key Hive Keys ──────────────────────────────────────
  static const String keyUserId = 'user_id';
  static const String keyLastSync = 'last_sync_timestamp';

  // ── App Lock ───────────────────────────────────────────
  // Decisão PO: 3 min de background dispara re-autenticação biométrica
  static const Duration appLockTimeout = Duration(minutes: 3);
  static const int appLockMaxFailures = 3;
}
