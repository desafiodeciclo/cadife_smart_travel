import '../../domain/entities/in_app_notification.dart';

abstract class INotificationRepository {
  Future<void> saveNotification(InAppNotification notification);
  
  Future<List<InAppNotification>> getNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  });
  
  Future<int> getUnreadCount();
  
  Future<void> markAsRead(String uuid);
  
  Future<void> markAllAsRead();
  
  Future<void> deleteNotification(String uuid);
  
  Future<void> deleteNotificationsByLeadId(String leadId);
  
  Stream<List<InAppNotification>> watchNotifications();
  
  Stream<int> watchUnreadCount();
}
