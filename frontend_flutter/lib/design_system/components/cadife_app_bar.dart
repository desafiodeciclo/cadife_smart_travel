import 'dart:ui';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class CadifeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CadifeAppBar({
    required this.title,
    super.key,
    this.showProfile = true,
    this.actions,
    this.centerTitle = true,
    this.transparent = true,
    this.showBackButton = false,
  });

  final String title;
  final bool showProfile;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool transparent;
  final bool showBackButton;

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
      leading: showBackButton 
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
              : null),
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
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
