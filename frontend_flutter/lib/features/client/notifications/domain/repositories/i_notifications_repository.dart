import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

abstract class INotificationsRepository {
  Future<Either<Failure, void>> initialize();
  Future<Either<Failure, String?>> getFcmToken();
  Future<Either<Failure, void>> subscribeToTopic(String topic);
  Future<Either<Failure, void>> unsubscribeFromTopic(String topic);
  Future<Either<Failure, void>> requestPermission();
  Stream<NotificationPayload> get onNotificationReceived;
}

class NotificationPayload {
  const NotificationPayload({
    required this.title,
    required this.body,
    this.data = const {},
    this.leadId,
  });

  final String title;
  final String body;
  final Map<String, dynamic> data;
  final String? leadId;
}
