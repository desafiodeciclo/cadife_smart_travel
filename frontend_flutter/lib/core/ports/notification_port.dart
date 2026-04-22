abstract class NotificationPort {
  Future<void> initialize();
  Future<String?> getFcmToken();
  Future<void> subscribeToTopic(String topic);
  Future<void> unsubscribeFromTopic(String topic);
  Future<void> requestPermission();
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