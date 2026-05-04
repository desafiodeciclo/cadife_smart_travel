import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Scaffold padrão do Cadife com suporte a AppBar configurável,
/// body com padding consistente e efeitos de fundo modernos.
class PageScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool useSafeArea;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final PreferredSizeWidget? appBar;
  final bool showBackgroundEffects;
  final bool extendBodyBehindAppBar;

  final bool showProfile;

  const PageScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.useSafeArea = true,
    this.padding,
    this.backgroundColor,
    this.appBar,
    this.showBackgroundEffects = true,
    this.extendBodyBehindAppBar = true,
    this.showProfile = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final effectiveAppBar = appBar ??
        (title != null
            ? CadifeAppBar(
                title: title!,
                actions: actions,
                showProfile: showProfile,
              )
            : null);

    Widget content = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: body,
    );

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? context.cadife.background,
      extendBody: true,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: effectiveAppBar,
      body: Stack(
        children: [
          if (showBackgroundEffects && isDark) ...[
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.8, 0.8)),
            ),
            Positioned(
              bottom: 100,
              left: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withValues(alpha: 0.05),
                ),
              ).animate().fadeIn(duration: 1200.ms).scale(begin: const Offset(0.5, 0.5)),
            ),
          ],
          content,
        ],
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
