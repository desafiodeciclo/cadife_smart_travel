import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Scaffold padrão do Cadife com suporte a AppBar configurável,
/// body com padding consistente e gradiente animado de fundo.
class PageScaffold extends StatefulWidget {
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
    required this.body,
    super.key,
    this.title,
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
  State<PageScaffold> createState() => _PageScaffoldState();
}

class _PageScaffoldState extends State<PageScaffold>
    with SingleTickerProviderStateMixin {

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;

    final effectiveAppBar = widget.appBar ??
        (widget.title != null
            ? CadifeAppBar(
                title: widget.title!,
                actions: widget.actions,
                showProfile: widget.showProfile,
              )
            : null);

    Widget content = Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: widget.body,
    );

    if (widget.useSafeArea) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      backgroundColor: widget.backgroundColor ?? cadife.background,
      extendBody: true,
      extendBodyBehindAppBar: widget.extendBodyBehindAppBar,
      appBar: effectiveAppBar,
      body: content,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: widget.bottomNavigationBar,
    );
  }
}
