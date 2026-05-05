import 'package:cadife_smart_travel/features/notifications/domain/entities/in_app_notification.dart';
import 'package:cadife_smart_travel/features/notifications/domain/repositories/i_notification_repository.dart';
import 'package:isar/isar.dart';

class NotificationIsarRepository implements INotificationRepository {
  final Isar _isar;
  
  const NotificationIsarRepository(this._isar);
  
  @override
  Future<void> saveNotification(InAppNotification notification) async {
    await _isar.writeTxn(() async {
      await _isar.inAppNotifications.put(notification);
    });
  }
  
  @override
  Future<List<InAppNotification>> getNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy> query;
    
    if (unreadOnly) {
      query = _isar.inAppNotifications
        .filter()
        .readIndexEqualTo(false)
        .sortByReceivedAtIndexDesc();
    } else {
      query = _isar.inAppNotifications
        .where()
        .sortByReceivedAtIndexDesc();
    }
    
    return await query
      .offset(offset)
      .limit(limit)
      .findAll();
  }
  
  @override
  Future<int> getUnreadCount() async {
    return await _isar.inAppNotifications
      .where()
      .readIndexEqualTo(false)
      .count();
  }
  
  @override
  Future<void> markAsRead(String uuid) async {
    final notification = await _isar.inAppNotifications
      .where()
      .uuidIndexEqualTo(uuid)
      .findFirst();
    
    if (notification != null) {
      await _isar.writeTxn(() async {
        notification.read = true;
        notification.readIndex = true;
        await _isar.inAppNotifications.put(notification);
      });
    }
  }
  
  @override
  Future<void> markAllAsRead() async {
    final unread = await _isar.inAppNotifications
      .where()
      .readIndexEqualTo(false)
      .findAll();
    
    await _isar.writeTxn(() async {
      for (final notif in unread) {
        notif.read = true;
        notif.readIndex = true;
        await _isar.inAppNotifications.put(notif);
      }
    });
  }
  
  @override
  Future<void> deleteNotification(String uuid) async {
    final notif = await _isar.inAppNotifications
      .where()
      .uuidIndexEqualTo(uuid)
      .findFirst();
    
    if (notif != null) {
      await _isar.writeTxn(() async {
        await _isar.inAppNotifications.delete(notif.id);
      });
    }
  }
  
  @override
  Future<void> deleteNotificationsByLeadId(String leadId) async {
    final notifications = await _isar.inAppNotifications
      .where()
      .leadIdIndexEqualTo(leadId)
      .findAll();
    
    await _isar.writeTxn(() async {
      await _isar.inAppNotifications.deleteAll(
        notifications.map((n) => n.id).toList(),
      );
    });
  }
  
  @override
  Stream<List<InAppNotification>> watchNotifications() {
    return _isar.inAppNotifications
      .where()
      .sortByReceivedAtIndexDesc()
      .watch(fireImmediately: true);
  }
  
  @override
  Stream<int> watchUnreadCount() {
    return _isar.inAppNotifications
      .where()
      .readIndexEqualTo(false)
      .count()
      .asStream();
  }
}
