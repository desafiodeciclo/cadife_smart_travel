import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AnalyticsService {
  // Verificação de segurança para evitar chamadas ao Firebase antes da inicialização
  bool get _isFirebaseInitialized => Firebase.apps.isNotEmpty;

  // Usar getters para evitar inicialização antes do Firebase.initializeApp()
  // e para permitir verificações de plataforma.
  FirebaseAnalytics? get _analytics {
    if (!_isFirebaseInitialized) return null;
    return FirebaseAnalytics.instance;
  }
  
  // Crashlytics não é suportado no Web.
  FirebaseCrashlytics? get _crashlytics {
    if (kIsWeb || !_isFirebaseInitialized) return null;
    return FirebaseCrashlytics.instance;
  }

  Future<void> init() async {
    // No Web, Firebase Analytics pode não estar inicializado se não houver configurações
    try {
      if (!_isFirebaseInitialized) {
        debugPrint('AnalyticsService: Firebase not initialized, skipping init.');
        return;
      }
      
      final packageInfo = await PackageInfo.fromPlatform();
      
      if (!kIsWeb && _crashlytics != null) {
        final deviceInfo = DeviceInfoPlugin();

        // App Version
        await _crashlytics!.setCustomKey('app_version', packageInfo.version);
        await _crashlytics!.setCustomKey('app_build_number', packageInfo.buildNumber);

        // Device Info
        if (defaultTargetPlatform == TargetPlatform.android) {
          final androidInfo = await deviceInfo.androidInfo;
          await _crashlytics!.setCustomKey('device_model', androidInfo.model);
          await _crashlytics!.setCustomKey('os_version', androidInfo.version.release);
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          final iosInfo = await deviceInfo.iosInfo;
          await _crashlytics!.setCustomKey('device_model', iosInfo.utsname.machine);
          await _crashlytics!.setCustomKey('os_version', iosInfo.systemVersion);
        }
        
        await _crashlytics!.setCustomKey('is_debug', kDebugMode);
      }
    } on Exception catch (e) {
      debugPrint('AnalyticsService.init failed: $e');
    }
  }

  Future<void> setUser(String? userId) async {
    try {
      await _analytics?.setUserId(id: userId);
      await _crashlytics?.setUserIdentifier(userId ?? '');
    } on Exception catch (e) {
      debugPrint('AnalyticsService.setUser failed: $e');
    }
  }

  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    try {
      final sanitizedParams = parameters != null ? _sanitizeParams(parameters) : null;
      await _analytics?.logEvent(name: name, parameters: sanitizedParams);
      await _crashlytics?.log('Event: $name ${sanitizedParams ?? ''}');
    } on Exception catch (e) {
      debugPrint('AnalyticsService.logEvent failed: $name, $e');
    }
  }

  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics?.logScreenView(screenName: screenName);
      await _crashlytics?.log('ScreenView: $screenName');
    } on Exception catch (e) {
      debugPrint('AnalyticsService.logScreenView failed: $screenName, $e');
    }
  }

  Future<void> logError(dynamic error, StackTrace? stack, {bool fatal = false}) async {
    try {
      await _crashlytics?.recordError(error, stack, fatal: fatal);
    } on Exception catch (e) {
      debugPrint('AnalyticsService.logError failed: $e');
    }
  }

  Future<void> logBreadcrumb(String message) async {
    try {
      await _crashlytics?.log(message);
    } on Exception catch (e) {
      debugPrint('AnalyticsService.logBreadcrumb failed: $e');
    }
  }

  Map<String, Object> _sanitizeParams(Map<String, dynamic> params) {
    final Map<String, Object> sanitized = Map<String, Object>.from(
      params.map((key, value) => MapEntry(key, value?.toString() ?? '')),
    );
    const piiKeys = ['email', 'password', 'phone', 'name', 'cpf', 'rg', 'address'];
    
    for (final key in piiKeys) {
      if (sanitized.containsKey(key)) {
        sanitized[key] = '[REDACTED]';
      }
    }
    
    return sanitized;
  }
}
