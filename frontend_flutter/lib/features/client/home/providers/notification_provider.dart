import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationModel {
  final String id;
  final String title;
  final DateTime timestamp;

  NotificationModel({
    required this.id,
    required this.title,
    required this.timestamp,
  });
}

class NotificationNotifier extends StateNotifier<List<NotificationModel>> {
  NotificationNotifier() : super([]);

  void addNotification(String title) {
    state = [
      ...state,
      NotificationModel(
        id: DateTime.now().toString(),
        title: title,
        timestamp: DateTime.now(),
      ),
    ];
  }

  void clearNotifications() {
    state = [];
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, List<NotificationModel>>((ref) {
  return NotificationNotifier();
});
