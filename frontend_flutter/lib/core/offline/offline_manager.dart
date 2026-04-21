import 'dart:async';

import 'package:cadife_smart_travel/core/constants/app_constants.dart';
import 'package:cadife_smart_travel/core/network/network_info.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Gerenciador de cache offline-first.
///
/// Inicializa Hive, monitora conectividade e coordena fallback para dados locais
/// quando o device perde conectividade — evita crash e flickering visual.
class OfflineManager {
  OfflineManager({required NetworkInfo networkInfo, HiveInterface? hive})
    : _networkInfo = networkInfo,
      _hive = hive ?? Hive;

  final NetworkInfo _networkInfo;
  final HiveInterface _hive;
  final _connectivityController = StreamController<bool>.broadcast();

  late Box<dynamic> _configBox;
  late Box<dynamic> _cacheBox;
  late Box<dynamic> _userPrefsBox;

  bool _isInitialized = false;

  /// Stream de status de conectividade.
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Snapshot atual de conectividade.
  bool get isOnline => _lastOnlineStatus;
  bool _lastOnlineStatus = true;

  /// Inicializa Hive e boxes necessários.
  Future<void> initialize() async {
    if (_isInitialized) return;

    final appDir = await getApplicationDocumentsDirectory();
    await _hive.initFlutter(appDir.path);

    _configBox = await _hive.openBox<dynamic>(AppConstants.hiveBoxConfig);
    _cacheBox = await _hive.openBox<dynamic>(AppConstants.hiveBoxCache);
    _userPrefsBox = await _hive.openBox<dynamic>(AppConstants.hiveBoxUser);

    _lastOnlineStatus = await _networkInfo.isConnected;

    _networkInfo.onConnectivityChanged.listen((isConnected) {
      _lastOnlineStatus = isConnected;
      _connectivityController.add(isConnected);
    });

    _isInitialized = true;
  }

  // ── Cache CRUD ─────────────────────────────────────────

  /// Salva dado no cache com timestamp.
  Future<void> saveToCache(String key, dynamic value) async {
    final entry = {
      'data': value,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await _cacheBox.put(key, entry);
  }

  /// Lê do cache. Retorna `null` se não existir ou expirou.
  dynamic getFromCache(String key, {int? expiryMinutes}) {
    final entry = _cacheBox.get(key);
    if (entry == null) return null;

    final timestamp = entry['timestamp'] as int;
    final expiry = expiryMinutes ?? AppConstants.offlineCacheExpiryMinutes;
    final isExpired =
        DateTime.now().millisecondsSinceEpoch - timestamp > expiry * 60 * 1000;

    if (isExpired) return null;
    return entry['data'];
  }

  /// Lê do cache mesmo se expirado (fallback offline).
  dynamic getFromCacheOffline(String key) {
    final entry = _cacheBox.get(key);
    return entry?['data'];
  }

  /// Verifica se existe cache válido para uma key.
  bool hasCachedData(String key, {int? expiryMinutes}) {
    return getFromCache(key, expiryMinutes: expiryMinutes) != null;
  }

  /// Remove entrada específica do cache.
  Future<void> removeFromCache(String key) async {
    await _cacheBox.delete(key);
  }

  /// Limpa todo o cache.
  Future<void> clearCache() async {
    await _cacheBox.clear();
  }

  // ── Config / User Prefs ────────────────────────────────

  Future<void> saveConfig(String key, dynamic value) async {
    await _configBox.put(key, value);
  }

  dynamic getConfig(String key) => _configBox.get(key);

  Future<void> saveUserPref(String key, dynamic value) async {
    await _userPrefsBox.put(key, value);
  }

  dynamic getUserPref(String key) => _userPrefsBox.get(key);

  /// Limpa dados do usuário (logout).
  Future<void> clearUserData() async {
    await _configBox.clear();
    await _userPrefsBox.clear();
  }

  /// Registra timestamp da última sincronização com o servidor.
  Future<void> markSynced() async {
    await _configBox.put(
      AppConstants.keyLastSync,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Retorna timestamp da última sincronização.
  int? get lastSyncTimestamp =>
      _configBox.get(AppConstants.keyLastSync) as int?;

  /// Verifica se os dados estão "frescos" (sync recente).
  bool get isDataFresh {
    final lastSync = lastSyncTimestamp;
    if (lastSync == null) return false;
    return DateTime.now().millisecondsSinceEpoch - lastSync <
        AppConstants.offlineCacheExpiryMinutes * 60 * 1000;
  }

  /// Fecha todas as boxes.
  Future<void> dispose() async {
    await _connectivityController.close();
    await _configBox.close();
    await _cacheBox.close();
    await _userPrefsBox.close();
  }
}
