import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Scaffold padrão do Cadife com suporte a AppBar configurável,
/// body com padding consistente e FAB opcional.
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
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAppBar = appBar ??
        (title != null
            ? CadifeAppBar(
                title: title!,
                actions: actions,
              )
            : null);

    Widget content = Padding(
      padding: padding ?? const EdgeInsets.all(0),
      child: body,
    );

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: effectiveAppBar,
      body: content,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
