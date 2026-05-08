import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/notifications/application/providers/notification_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCountAsync = ref.watch(unreadCountStreamProvider);
    final theme = context.cadife;
    
    return unreadCountAsync.when(
      data: (count) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () => context.push('/notifications'),
              icon: Icon(
                LucideIcons.bell,
                color: theme.textPrimary,
              ),
              tooltip: 'Notificações',
            ),
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: theme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.background, width: 2),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => IconButton(
        onPressed: () => context.push('/notifications'),
        icon: Icon(LucideIcons.bell, color: theme.textPrimary),
        tooltip: 'Notificações',
      ),
      error: (_, _) => IconButton(
        onPressed: () => context.push('/notifications'),
        icon: Icon(LucideIcons.bell, color: theme.textPrimary),
        tooltip: 'Notificações',
      ),
    );
  }
}
