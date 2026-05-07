import 'package:cadife_smart_travel/features/notifications/domain/entities/in_app_notification.dart';
import 'package:cadife_smart_travel/features/notifications/domain/repositories/i_notification_repository.dart';

class MockNotificationRepository implements INotificationRepository {
  const MockNotificationRepository();

  @override
  Future<void> saveNotification(InAppNotification notification) async {}

  @override
  Future<List<InAppNotification>> getNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async => [];

  @override
  Future<int> getUnreadCount() async => 0;

  @override
  Future<void> markAsRead(String uuid) async {}

  @override
  Future<void> markAllAsRead() async {}

  @override
  Future<void> deleteNotification(String uuid) async {}

  @override
  Future<void> deleteNotificationsByLeadId(String leadId) async {}

  @override
  Stream<List<InAppNotification>> watchNotifications() => Stream.value([]);

  @override
  Stream<int> watchUnreadCount() => Stream.value(0);
}
