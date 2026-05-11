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
}

// Mock notifications
final mockNotifications = [
  Notification(
    id: '1',
    title: 'Novo Lead Qualificado',
    body: 'João Silva foi qualificado para curadoria',
    type: 'lead_qualified',
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    isRead: false,
  ),
  Notification(
    id: '2',
    title: 'Agendamento Confirmado',
    body: 'Maria Santos confirmou horário para amanhã 14:00',
    type: 'schedule_confirmed',
    timestamp: DateTime.now().subtract(const Duration(hours: 4)),
    isRead: true,
  ),
  Notification(
    id: '3',
    title: 'Proposta Aceita',
    body: 'Carlos Santos aceitou sua proposta de viagem',
    type: 'proposal_accepted',
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    isRead: true,
  ),
];

class NotificationsNotifier extends AsyncNotifier<List<Notification>> {
  @override
  Future<List<Notification>> build() async {
    // Por enquanto, retorna mock
    // Depois: buscar do backend via GET /notifications
    return mockNotifications;
  }

  Future<void> markAsRead(String notificationId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(current.map((n) {
      if (n.id != notificationId) return n;
      return Notification(
        id: n.id,
        title: n.title,
        body: n.body,
        type: n.type,
        timestamp: n.timestamp,
        isRead: true,
      );
    }).toList());
    // TODO: POST /notifications/{id}/mark-as-read ao integrar backend
  }

  Future<void> deleteNotification(String notificationId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(
      current.where((n) => n.id != notificationId).toList(),
    );
  }
}

final notificationsProvider = AsyncNotifierProvider<NotificationsNotifier, List<Notification>>(
  () => NotificationsNotifier(),
);
