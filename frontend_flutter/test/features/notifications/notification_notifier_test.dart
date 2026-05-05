import 'package:cadife_smart_travel/features/notifications/application/providers/notification_providers.dart';
import 'package:cadife_smart_travel/features/notifications/domain/entities/in_app_notification.dart';
import 'package:cadife_smart_travel/features/notifications/domain/repositories/i_notification_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationRepository extends Mock implements INotificationRepository {}

void main() {
  late MockNotificationRepository mockRepo;
  late ProviderContainer container;
  
  setUp(() {
    mockRepo = MockNotificationRepository();
    container = ProviderContainer(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });
  
  tearDown(() {
    container.dispose();
  });
  
  group('NotificationNotifier', () {
    test('markAsRead chama o repositório', () async {
      const uuid = 'notif-001';
      when(() => mockRepo.markAsRead(uuid)).thenAnswer((_) async {});
      
      final notifier = container.read(notificationNotifierProvider.notifier);
      await notifier.markAsRead(uuid);
      
      verify(() => mockRepo.markAsRead(uuid)).called(1);
    });
    
    test('markAllAsRead chama o repositório', () async {
      when(() => mockRepo.markAllAsRead()).thenAnswer((_) async {});
      
      final notifier = container.read(notificationNotifierProvider.notifier);
      await notifier.markAllAsRead();
      
      verify(() => mockRepo.markAllAsRead()).called(1);
    });
    
    test('deleteNotification chama o repositório', () async {
      const uuid = 'notif-001';
      when(() => mockRepo.deleteNotification(uuid)).thenAnswer((_) async {});
      
      final notifier = container.read(notificationNotifierProvider.notifier);
      await notifier.deleteNotification(uuid);
      
      verify(() => mockRepo.deleteNotification(uuid)).called(1);
    });
  });
}
