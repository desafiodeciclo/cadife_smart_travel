import 'package:cadife_smart_travel/features/notifications/application/providers/notification_providers.dart';
import 'package:cadife_smart_travel/features/notifications/domain/entities/in_app_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NotificationTile extends ConsumerWidget {
  final InAppNotification notification;
  
  const NotificationTile({super.key, required this.notification});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Dismissible(
      key: ValueKey(notification.uuid),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) async {
        await ref
          .read(notificationNotifierProvider.notifier)
          .deleteNotification(notification.uuid);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notificação deletada'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      background: Container(
        color: colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(
          Icons.delete_outline,
          color: colorScheme.error,
        ),
      ),
      child: InkWell(
        onTap: () async {
          if (!notification.read) {
            await ref
              .read(notificationNotifierProvider.notifier)
              .markAsRead(notification.uuid);
          }
          
          if (notification.actionUrl != null && context.mounted) {
            context.go(notification.actionUrl!);
          }
        },
        child: Container(
          color: notification.read
              ? Colors.transparent
              : colorScheme.surfaceContainerHigh,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Indicador de leitura
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: notification.read
                      ? Colors.transparent
                      : colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              
              // Ícone do tipo
              _NotificationTypeIcon(type: notification.type),
              const SizedBox(width: 12),
              
              // Conteúdo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: notification.read
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (notification.leadName != null)
                          Flexible(
                            child: Text(
                              ' — ${notification.leadName}',
                              style: textTheme.labelSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    
                    Text(
                      _formatTimeAgo(notification.receivedAt),
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'agora';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return 'há $minutes ${minutes == 1 ? 'minuto' : 'minutos'}';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'há $hours ${hours == 1 ? 'hora' : 'horas'}';
    } else {
      final days = difference.inDays;
      return 'há $days ${days == 1 ? 'dia' : 'dias'}';
    }
  }
}

class _NotificationTypeIcon extends StatelessWidget {
  final NotificationType type;
  
  const _NotificationTypeIcon({required this.type});
  
  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      NotificationType.novoLead => (
        Icons.person_add,
        Colors.blue,
      ),
      NotificationType.leadQualificado => (
        Icons.star,
        Colors.amber,
      ),
      NotificationType.agendamentoConfirmado => (
        Icons.event_available,
        Colors.green,
      ),
      NotificationType.leadInativo => (
        Icons.warning_amber,
        Colors.orange,
      ),
      NotificationType.propostaEnviada => (
        Icons.send,
        Colors.blue,
      ),
      NotificationType.propostaAprovada => (
        Icons.check_circle,
        Colors.green,
      ),
      NotificationType.sistemaAlerta => (
        Icons.info,
        Colors.grey,
      ),
    };
    
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
      ),
      child: Icon(
        icon,
        size: 18,
        color: color,
      ),
    );
  }
}
