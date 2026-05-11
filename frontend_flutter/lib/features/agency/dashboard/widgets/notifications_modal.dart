import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/providers/notifications_provider.dart' as np;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


class NotificationsModal extends ConsumerWidget {
  const NotificationsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(np.notificationsProvider);
    final theme = context.cadife;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notificações',
                  style: AppTextStyles.h4.copyWith(fontSize: 20),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          notificationsAsync.when(
            data: (notifications) {
              if (notifications.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(LucideIcons.bellOff, size: 48, color: theme.textSecondary.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma notificação por enquanto',
                        style: TextStyle(color: theme.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: notifications.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _NotificationTile(notification: notification);
                  },
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, st) => Padding(
              padding: const EdgeInsets.all(40),
              child: Text('Erro ao carregar notificações: $err'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final np.Notification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.cadife;
    final timeStr = DateFormat.Hm().format(notification.timestamp);
    final dateStr = DateFormat('dd/MM').format(notification.timestamp);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(LucideIcons.trash2, color: AppColors.error),
      ),
      onDismissed: (_) {
        ref.read(np.notificationsProvider.notifier).deleteNotification(notification.id);
      },
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            ref.read(np.notificationsProvider.notifier).markAsRead(notification.id);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead 
                ? Colors.transparent 
                : theme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead 
                  ? theme.textPrimary.withValues(alpha: 0.05)
                  : theme.primary.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getIconColor(notification.type).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIcon(notification.type),
                  color: _getIconColor(notification.type),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                              fontSize: 14,
                              color: theme.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '$dateStr $timeStr',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textSecondary.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'lead_qualified':
        return LucideIcons.userCheck;
      case 'schedule_confirmed':
        return LucideIcons.calendarCheck;
      case 'proposal_accepted':
        return LucideIcons.circleCheck;
      default:
        return LucideIcons.bell;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'lead_qualified':
        return AppColors.info;
      case 'schedule_confirmed':
        return AppColors.warning;
      case 'proposal_accepted':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }
}
