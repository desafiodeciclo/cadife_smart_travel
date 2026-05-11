import 'package:cadife_smart_travel/features/client/notifications/domain/entities/app_notification.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  // Simula um atraso de rede para melhor UX demonstrativa
  await Future.delayed(const Duration(milliseconds: 1000));
  
  return [
    AppNotification(
      id: '1',
      title: 'Oferta especial!',
      message: 'Desconto de 20% em viagens para o Caribe',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      type: NotificationType.offer,
    ),
    AppNotification(
      id: '2',
      title: 'Atualização de Viagem',
      message: 'Seu roteiro para Paris foi atualizado com novos detalhes.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      type: NotificationType.tripUpdate,
      isRead: true,
    ),
    AppNotification(
      id: '3',
      title: 'Nova Mensagem',
      message: 'O consultor João enviou uma mensagem sobre sua reserva.',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      type: NotificationType.message,
    ),
    AppNotification(
      id: '4',
      title: 'Alerta de Documento',
      message: 'Seu passaporte expira em menos de 6 meses. Verifique!',
      timestamp: DateTime.now().subtract(const Duration(days: 5)),
      type: NotificationType.alert,
    ),
  ];
});
