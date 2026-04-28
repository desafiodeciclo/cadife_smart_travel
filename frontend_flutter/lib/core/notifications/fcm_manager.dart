import 'dart:developer' as developer;

import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:cadife_smart_travel/core/notifications/local_notification_manager.dart';
import 'package:cadife_smart_travel/core/ports/auth_port.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FCMManager {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    // Solicitar permissões
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    developer.log('User granted permission: ${settings.authorizationStatus}', name: 'FCMManager');

    // Recuperar o token FCM
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        developer.log('FCM Token: $token', name: 'FCMManager');
        // Registrar o token de forma síncrona
        final authPort = sl<AuthPort>();
        await authPort.saveFcmToken(token);
      }
    } catch (e, stackTrace) {
      developer.log('Erro ao registrar FCM token', error: e, stackTrace: stackTrace, name: 'FCMManager');
    }

    // Configurar listener para foreground
    FirebaseMessaging.onMessage.listen((message) {
      developer.log('Recebido mensagem FCM Foreground: ${message.messageId}', name: 'FCMManager');
      if (message.notification != null) {
        LocalNotificationManager.showNotification(
          id: message.hashCode,
          title: message.notification!.title ?? 'Notificação',
          body: message.notification!.body ?? '',
        );
      }
    });

    // Handle token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      developer.log('Token FCM atualizado: $newToken', name: 'FCMManager');
      try {
        await sl<AuthPort>().saveFcmToken(newToken);
      } catch (e) {
        developer.log('Erro ao atualizar FCM token', error: e, name: 'FCMManager');
      }
    });
  }
}
