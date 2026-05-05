import 'dart:developer' as developer;

import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:cadife_smart_travel/core/notifications/local_notification_manager.dart';
import 'package:cadife_smart_travel/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:cadife_smart_travel/features/notifications/domain/dtos/notification_payload_dto.dart';
import 'package:cadife_smart_travel/features/notifications/domain/entities/in_app_notification.dart';
import 'package:cadife_smart_travel/features/notifications/domain/repositories/i_notification_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_it/get_it.dart';

class FCMManager {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    // Solicitar permissÃµes
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
    FirebaseMessaging.onMessage.listen((message) async {
      developer.log(
        'Recebido mensagem FCM Foreground: ${message.messageId}',
        name: 'FCMManager',
      );

      // Persistir no banco local
      try {
        final payloadDTO = NotificationPayloadDTO.fromFirebaseMessage(message);
        final repo = sl<INotificationRepository>();

        final notification = InAppNotification(
          uuid: payloadDTO.id,
          leadId: payloadDTO.leadId,
          type: payloadDTO.type,
          title: payloadDTO.title,
          body: payloadDTO.body,
          receivedAt: payloadDTO.receivedAt,
          actionUrl: '/leads/${payloadDTO.leadId}',
          leadName: payloadDTO.leadName,
          leadPhone: payloadDTO.leadPhone,
        );

        await repo.saveNotification(notification);
        developer.log('Notificação persistida no Isar.', name: 'FCMManager');
      } catch (e) {
        developer.log('Erro ao persistir notificação: $e', name: 'FCMManager');
      }

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

    // Configurar listener para quando o app é aberto via notificação
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      developer.log(
        'App aberto via notificação: ${message.messageId}',
        name: 'FCMManager',
      );
      // O tratamento de navegação será feito via GoRouter ou no contexto da UI
      // Aqui podemos apenas registrar o evento ou preparar o estado
    });

    // Handle token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      developer.log('Token FCM atualizado: $newToken', name: 'FCMManager');
      await _sendTokenIfAuthenticated(newToken);
    });
  }

  /// Envia o token FCM para o backend **apenas se o usuÃ¡rio estiver autenticado**.
  /// Deve ser chamado apÃ³s o login bem-sucedido.
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
      final authRepository = GetIt.instance<IAuthRepository>();
      final isLoggedInResult = await authRepository.isLoggedIn();
      final isLoggedIn = isLoggedInResult.getOrElse((_) => false);
      if (!isLoggedIn) {
        developer.log(
          'Usuário não autenticado — token FCM não enviado.',
          name: 'FCMManager',
        );
        return;
      }
      await authRepository.saveFcmToken(token);
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


