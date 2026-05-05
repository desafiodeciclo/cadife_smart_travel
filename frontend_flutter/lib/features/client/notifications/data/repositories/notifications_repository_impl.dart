import 'dart:async';

import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/client/notifications/domain/repositories/i_notifications_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fpdart/fpdart.dart';

class NotificationsRepositoryImpl implements INotificationsRepository {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final _notificationController = StreamController<NotificationPayload>.broadcast();

  @override
  Stream<NotificationPayload> get onNotificationReceived => _notificationController.stream;

  @override
  Future<Either<Failure, void>> initialize() async {
    try {
      FirebaseMessaging.onMessage.listen((message) {
        if (message.notification != null) {
          _notificationController.add(NotificationPayload(
            title: message.notification!.title ?? '',
            body: message.notification!.body ?? '',
            data: message.data,
            leadId: message.data['lead_id'] as String?,
          ));
        }
      });
      return const Right(null);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, String?>> getFcmToken() async {
    try {
      final token = await _messaging.getToken();
      return Right(token);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      return const Right(null);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      return const Right(null);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> requestPermission() async {
    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return const Right(null);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  void dispose() {
    _notificationController.close();
  }
}
