import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/notifications/application/providers/notification_providers.dart';
import 'package:cadife_smart_travel/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});
  
  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  late ScrollController _scrollController;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final unreadCountAsync = ref.watch(unreadCountStreamProvider);
    
    return PageScaffold(
      appBar: CadifeAppBar(
        title: 'Notificações',
        showProfile: false,
        showNotificationBell: false,
        actions: [
          // Botão "Marcar tudo como lido" (aparece apenas se há não lidas)
          unreadCountAsync.when(
            data: (count) {
              if (count > 0) {
                return CadifeButton(
                  text: 'Marcar tudo',
                  variant: ButtonVariant.ghost,
                  icon: Icons.done_all,
                  analyticsLabel: 'notifications_mark_all_read',
                  onPressed: () async {
                    await ref
                        .read(notificationNotifierProvider.notifier)
                        .markAllAsRead();
                    if (context.mounted) {
                      ShadToaster.of(context).show(
                        const ShadToast(
                          description: Text('Todas as notificações marcadas como lidas'),
                        ),
                      );
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const AppEmptyStateWidget(
              icon: Icons.notifications_none,
              title: 'Nenhuma notificação',
              subtitle: 'Notificações de leads qualificados aparecerão aqui',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsStreamProvider);
            },
            child: ListView.builder(
              controller: _scrollController,
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return NotificationTile(notification: notification);
              },
            ),
          );
        },
        loading: () => const AppLoadingWidget(),
        error: (error, stack) => AppErrorWidget(
          message: 'Erro ao carregar notificações',
          onRetry: () => ref.invalidate(notificationsStreamProvider),
        ),
      ),
    );
  }
}
