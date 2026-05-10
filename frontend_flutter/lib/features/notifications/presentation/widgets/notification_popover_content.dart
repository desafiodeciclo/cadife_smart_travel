import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/notifications/application/providers/notification_providers.dart';
import 'package:cadife_smart_travel/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationPopoverContent extends ConsumerWidget {
  final VoidCallback onClose;

  const NotificationPopoverContent({
    required this.onClose,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.cadife;
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final unreadCountAsync = ref.watch(unreadCountStreamProvider);

    return Container(
      width: 350,
      constraints: const BoxConstraints(maxHeight: 500),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notificações',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                unreadCountAsync.when(
                  data: (count) => count > 0
                      ? TextButton(
                          onPressed: () => ref
                              .read(notificationNotifierProvider.notifier)
                              .markAllAsRead(),
                          child: Text(
                            'Marcar tudo como lido',
                            style: TextStyle(
                              color: theme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),
          // Content
          Flexible(
            child: notificationsAsync.when(
              data: (notifications) {
                if (notifications.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.primary.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.bellOff,
                            color: theme.textSecondary.withValues(alpha: 0.5),
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sua caixa de notificações está vazia',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: notifications.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, thickness: 0.5),
                  itemBuilder: (context, index) {
                    return NotificationTile(notification: notifications[index]);
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(48),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.circleAlert, color: AppColors.error, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      'Erro ao carregar notificações',
                      style: TextStyle(color: theme.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Footer
          const Divider(height: 1, thickness: 0.5),
          InkWell(
            onTap: onClose,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              child: Text(
                'Fechar',
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
