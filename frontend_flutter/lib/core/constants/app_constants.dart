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
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyLastSync = 'last_sync_timestamp';

  // ── Security ───────────────────────────────────────────
  static const String secureStorageKey = 'cadife_secure_key';
  static const String pinningKeyAlias = 'certificate_pins';
}
