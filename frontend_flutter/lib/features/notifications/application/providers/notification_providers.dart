import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import 'package:cadife_smart_travel/core/cache/isar_cache_manager.dart';
import 'package:cadife_smart_travel/core/di/service_locator.dart';
import '../../domain/entities/in_app_notification.dart';
import '../../domain/repositories/i_notification_repository.dart';
import '../../infrastructure/database/notification_isar.dart';

// Repositório
final notificationRepositoryProvider = Provider<INotificationRepository>((ref) {
  return sl<INotificationRepository>();
});

// Stream de todas as notificações
final notificationsStreamProvider = StreamProvider<List<InAppNotification>>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.watchNotifications();
});

// Stream de contador de não lidas
final unreadCountStreamProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.watchUnreadCount();
});

// Notifier para ações (marcar como lido, deletar, etc.)
class NotificationNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Apenas para expor métodos de ação
  }
  
  Future<void> markAsRead(String uuid) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.markAsRead(uuid);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
  
  Future<void> markAllAsRead() async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.markAllAsRead();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
  
  Future<void> deleteNotification(String uuid) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.deleteNotification(uuid);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
  
  Future<void> deleteNotificationsByLeadId(String leadId) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.deleteNotificationsByLeadId(leadId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final notificationNotifierProvider = 
  AsyncNotifierProvider<NotificationNotifier, void>(
    () => NotificationNotifier(),
  );
