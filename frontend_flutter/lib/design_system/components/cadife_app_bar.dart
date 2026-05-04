import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/status/presentation/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class CadifeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CadifeAppBar({
    super.key,
    required this.title,
    this.showProfile = true,
    this.actions,
    this.centerTitle = true,
  });

  final String title;
  final bool showProfile;
  final List<Widget>? actions;
  final bool centerTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);
    final cadife = context.cadife;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      backgroundColor: isDark ? AppColors.darkSurface : cadife.primary,
      elevation: 0,
      centerTitle: centerTitle,
      leading: showProfile
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => context.go('/client/perfil'),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  child: const Icon(Icons.person, color: Colors.white, size: 18),
                ),
              ),
            )
          : null,
      title: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 16,
          letterSpacing: 2.0,
        ),
      ),
      actions: [
        if (actions != null) ...actions!,
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Badge(
            isLabelVisible: notifications.isNotEmpty,
            backgroundColor: Colors.white,
            label: Text(
              '${notifications.length}',
              style: TextStyle(color: cadife.primary, fontSize: 10),
            ),
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

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
