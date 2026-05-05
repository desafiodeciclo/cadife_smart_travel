import 'dart:ui';
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
    this.transparent = true,
  });

  final String title;
  final bool showProfile;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool transparent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);
    final theme = context.cadife;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: centerTitle,
      flexibleSpace: transparent 
        ? ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: theme.background.withValues(alpha: 0.2),
              ),
            ),
          )
        : null,
      leading: showProfile
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => context.go('/client/perfil'),
                child: CircleAvatar(
                  backgroundColor: theme.textPrimary.withValues(alpha: 0.1),
                  child: Icon(
                    LucideIcons.user, 
                    color: theme.textPrimary, 
                    size: 18
                  ),
                ),
              ),
            )
          : null,
      title: Text(
        title,
        style: GoogleFonts.inter(
          color: theme.textPrimary,
          fontWeight: FontWeight.w900,
          fontSize: 18,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        if (actions != null) ...actions!,
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Badge(
            isLabelVisible: notifications.isNotEmpty,
            backgroundColor: theme.primary,
            label: Text(
              '${notifications.length}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            child: PopupMenuButton<String>(
              tooltip: '',
              icon: Icon(
                LucideIcons.bell, 
                color: theme.textPrimary
              ),
              offset: const Offset(0, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.cardBorder),
              ),
              color: theme.cardBackground,
              itemBuilder: (context) {
                if (notifications.isEmpty) {
                  return [
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Text(
                        'Sem notificações',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.textSecondary,
                        ),
                      ),
                    ),
                  ];
                }
                return notifications.map((n) {
                  return PopupMenuItem<String>(
                    value: n.id,
                    child: Text(
                      n.title,
                      style: GoogleFonts.inter(color: theme.textPrimary),
                    ),
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
