import 'dart:developer' as developer;

import 'package:cadife_smart_travel/core/notifications/local_notification_manager.dart';
import 'package:cadife_smart_travel/core/ports/auth_port.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_it/get_it.dart';

class FCMManager {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    // Solicitar permissões
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    developer.log(
      'User granted permission: ${settings.authorizationStatus}',
      name: 'FCMManager',
    );

    // Configurar listener para foreground
    FirebaseMessaging.onMessage.listen((message) {
      developer.log(
        'Recebido mensagem FCM Foreground: ${message.messageId}',
        name: 'FCMManager',
      );
      if (message.notification != null) {
        // Usa messageId (quando disponível) para evitar colisões de hashCode.
        final id = message.messageId?.hashCode ?? message.hashCode;
        LocalNotificationManager.showNotification(
          id: id,
          title: message.notification!.title ?? 'Notificação',
          body: message.notification!.body ?? '',
        );
      }
    });

    // Handle token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      developer.log('Token FCM atualizado: $newToken', name: 'FCMManager');
      await _sendTokenIfAuthenticated(newToken);
    });
  }

  /// Envia o token FCM para o backend **apenas se o usuário estiver autenticado**.
  /// Deve ser chamado após o login bem-sucedido.
  static Future<void> sendTokenToBackend() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _sendTokenIfAuthenticated(token);
      }
    } catch (e, stackTrace) {
      developer.log(
        'Erro ao recuperar FCM token',
        error: e,
        stackTrace: stackTrace,
        name: 'FCMManager',
      );
    }
  }

  static Future<void> _sendTokenIfAuthenticated(String token) async {
    try {
      final authPort = GetIt.instance<AuthPort>();
      final isLoggedIn = await authPort.isLoggedIn();
      if (!isLoggedIn) {
        developer.log(
          'Usuário não autenticado — token FCM não enviado.',
          name: 'FCMManager',
        );
        return;
      }
      await authPort.saveFcmToken(token);
      developer.log('FCM Token registrado no backend.', name: 'FCMManager');
    } catch (e, stackTrace) {
      developer.log(
        'Erro ao registrar FCM token',
        error: e,
        stackTrace: stackTrace,
        name: 'FCMManager',
      );
    }
  }
}
