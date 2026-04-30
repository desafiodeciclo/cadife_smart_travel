import 'package:cadife_smart_travel/core/theme/app_colors.dart';
import 'package:cadife_smart_travel/features/client/home/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CadifeAppBar extends ConsumerWidget {
  const CadifeAppBar({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);
    
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.primary,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => context.go('/client/perfil'),
          child: CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ),
      ),
      title: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 17,
          letterSpacing: 2.5,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Badge(
            isLabelVisible: notifications.isNotEmpty,
            backgroundColor: Colors.red,
            smallSize: 10,
            child: PopupMenuButton<String>(
              tooltip: '',
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              offset: const Offset(0, 45),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              itemBuilder: (context) {
                if (notifications.isEmpty) {
                  return [
                    const PopupMenuItem<String>(
                      enabled: false,
                      child: Text(
                        'Sem notificações',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ];
                }
                return notifications.map((n) {
                  return PopupMenuItem<String>(
                    value: n.id,
                    child: Text(n.title),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ],
    );
  }
}
