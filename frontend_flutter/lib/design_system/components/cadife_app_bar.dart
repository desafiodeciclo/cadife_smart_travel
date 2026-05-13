import 'dart:ui';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class CadifeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CadifeAppBar({
    this.title,
    super.key,
    this.showProfile = true,
    this.actions,
    this.centerTitle = true,
    this.transparent = true,
    this.showBackButton = false,
    this.titleWidget,
    this.leading,
  });

  final String? title;
  final Widget? titleWidget;
  final bool showProfile;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool transparent;
  final bool showBackButton;
  final Widget? leading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      leading: leading ?? (showBackButton 
          ? IconButton(
              icon: const Icon(LucideIcons.arrowLeft),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                }
              },
            )
          : (showProfile
              ? Padding(
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: () {
                      final user = ref.read(authNotifierProvider).valueOrNull;
                      if (user?.role == UserRole.consultor ||
                          user?.role == UserRole.admin) {
                        context.go('/agency/profile');
                      } else {
                        context.go('/client/profile');
                      }
                    },
                    child: Builder(
                      builder: (context) {
                        final user = ref.watch(authNotifierProvider).valueOrNull;
                        return CircleAvatar(
                          backgroundColor: theme.textPrimary.withValues(alpha: 0.1),
                          backgroundImage: user?.avatarUrl != null
                              ? NetworkImage(user!.avatarUrl!)
                              : null,
                          child: user?.avatarUrl == null
                              ? Icon(
                                  LucideIcons.user,
                                  color: theme.textPrimary,
                                  size: 18,
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                )
              : null)),
      title: titleWidget ?? (title != null ? Text(
        title!.length > 30 ? '${title!.substring(0, 28)}…' : title!.toUpperCase(),
        style: GoogleFonts.inter(
          color: theme.textPrimary,
          fontWeight: FontWeight.w900,
          fontSize: 16,
          letterSpacing: 1.2,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ) : null),
      actions: [
        if (actions != null) ...actions!,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
