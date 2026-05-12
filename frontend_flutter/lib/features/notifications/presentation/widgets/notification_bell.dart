import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/notifications/application/providers/notification_providers.dart';
import 'package:cadife_smart_travel/features/notifications/presentation/widgets/notification_popover_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationBell extends ConsumerStatefulWidget {
  const NotificationBell({super.key});

  @override
  ConsumerState<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<NotificationBell> {
  final popoverController = ShadPopoverController();

  @override
  void dispose() {
    popoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.cadife;
    final unreadCountAsync = ref.watch(unreadCountStreamProvider);

    return unreadCountAsync.when(
      data: (count) {
        return ShadPopover(
          controller: popoverController,
          anchor: const ShadAnchorAuto(),
          popover: (context) => NotificationPopoverContent(
            onClose: popoverController.hide,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: popoverController.toggle,
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
                      color: AppColors.error,
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
          ),
        );
      },
      loading: () => IconButton(
        onPressed: null,
        icon: Icon(LucideIcons.bell, color: theme.textPrimary.withValues(alpha: 0.5)),
        tooltip: 'Notificações',
      ),
      error: (_, _) => IconButton(
        onPressed: null,
        icon: Icon(LucideIcons.bellOff, color: theme.textPrimary.withValues(alpha: 0.5)),
        tooltip: 'Notificações',
      ),
    );
  }
}
