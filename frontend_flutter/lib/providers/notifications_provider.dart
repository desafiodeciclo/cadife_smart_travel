import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:cadife_smart_travel/features/notifications/domain/entities/in_app_notification.dart';
import 'package:cadife_smart_travel/features/notifications/domain/repositories/i_notification_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Notification {
  final String id;
  final String title;
  final String body;
  final String type; // 'lead_qualified', 'schedule_confirmed', etc
  final DateTime timestamp;
  final bool isRead;

  Notification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  factory Notification.fromInApp(InAppNotification n) {
    return Notification(
      id: n.uuid,
      title: n.title,
      body: n.body,
      type: _mapType(n.type),
      timestamp: n.receivedAt,
      isRead: n.read,
    );
  }

  static String _mapType(NotificationType type) {
    switch (type) {
      case NotificationType.leadQualificado:
        return 'lead_qualified';
      case NotificationType.agendamentoConfirmado:
        return 'schedule_confirmed';
      case NotificationType.propostaAprovada:
      case NotificationType.propostaEnviada:
        return 'proposal_accepted';
      default:
        return 'default';
    }
  }
}

class NotificationsNotifier extends AsyncNotifier<List<Notification>> {
  INotificationRepository get _repo => sl<INotificationRepository>();

  @override
  Future<List<Notification>> build() async {
    final items = await _repo.getNotifications();
    return items.map(Notification.fromInApp).toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await _repo.markAsRead(notificationId);
    ref.invalidateSelf();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _repo.deleteNotification(notificationId);
    ref.invalidateSelf();
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<Notification>>(
  NotificationsNotifier.new,
);
