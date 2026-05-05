import 'package:cadife_smart_travel/features/notifications/domain/entities/in_app_notification.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:uuid/uuid.dart';

class NotificationPayloadDTO {
  final String id;
  final String leadId;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime receivedAt;
  final String? leadName;
  final String? leadPhone;

  NotificationPayloadDTO({
    required this.id,
    required this.leadId,
    required this.type,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.leadName,
    this.leadPhone,
  });
  
  NotificationPayloadDTO.fromFirebaseMessage(RemoteMessage message) :
    id = message.data['notification_id'] ?? const Uuid().v4(),
    leadId = message.data['lead_id'] ?? '',
    type = _parseNotificationType(message.data['type']),
    title = message.notification?.title ?? 'Notificação',
    body = message.notification?.body ?? '',
    receivedAt = DateTime.now(),
    leadName = message.data['lead_name'],
    leadPhone = message.data['lead_phone'];
  
  // Fábrica para teste
  factory NotificationPayloadDTO.mock({
    required String leadId,
    required NotificationType type,
  }) => NotificationPayloadDTO(
    id: const Uuid().v4(),
    leadId: leadId,
    type: type,
    title: type.label,
    body: 'Mock notification para testes',
    receivedAt: DateTime.now(),
    leadName: 'João Silva',
    leadPhone: '+5511999887766',
  );

  static NotificationType _parseNotificationType(String? typeStr) {
    if (typeStr == null) return NotificationType.sistemaAlerta;
    try {
      return NotificationType.values.byName(typeStr);
    } on Exception catch (_) {
      return NotificationType.sistemaAlerta;
    }
  }
}
