import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  Future<void> init() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = DeviceInfoPlugin();

    // App Version
    await _crashlytics.setCustomKey('app_version', packageInfo.version);
    await _crashlytics.setCustomKey('app_build_number', packageInfo.buildNumber);

    // Device Info
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      await _crashlytics.setCustomKey('device_model', androidInfo.model);
      await _crashlytics.setCustomKey('os_version', androidInfo.version.release);
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      await _crashlytics.setCustomKey('device_model', iosInfo.utsname.machine);
      await _crashlytics.setCustomKey('os_version', iosInfo.systemVersion);
    }
    
    await _crashlytics.setCustomKey('is_debug', kDebugMode);
  }

  Future<void> setUser(String? userId) async {
    await _analytics.setUserId(id: userId);
    await _crashlytics.setUserIdentifier(userId ?? '');
  }

  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    // Sanitização de PII (básico: remover campos comuns que podem conter PII se não forem tratados)
    final sanitizedParams = parameters != null ? _sanitizeParams(parameters) : null;
    
    await _analytics.logEvent(name: name, parameters: sanitizedParams);
    
    // Também adiciona como log no Crashlytics para contexto (breadcrumbs)
    await _crashlytics.log('Event: $name ${sanitizedParams ?? ''}');
  }

  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
    await _crashlytics.log('ScreenView: $screenName');
  }

  Future<void> logError(dynamic error, StackTrace? stack, {bool fatal = false}) async {
    await _crashlytics.recordError(error, stack, fatal: fatal);
  }

  Future<void> logBreadcrumb(String message) async {
    await _crashlytics.log(message);
  }

  Map<String, Object> _sanitizeParams(Map<String, dynamic> params) {
    final Map<String, Object> sanitized = Map<String, Object>.from(params);
    const piiKeys = ['email', 'password', 'phone', 'name', 'cpf', 'rg', 'address'];
    
    for (final key in piiKeys) {
      if (sanitized.containsKey(key)) {
        sanitized[key] = '[REDACTED]';
      }
    }
    
    return sanitized;
  }
}
