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
  late final AnimationController _gradientController;
  late final Animation<Alignment> _beginAlignment;
  late final Animation<Alignment> _endAlignment;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _beginAlignment = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: const Alignment(-1.0, -1.0),
          end: const Alignment(0.5, -0.8),
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: const Alignment(0.5, -0.8),
          end: const Alignment(-1.0, -1.0),
        ),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    ));

    _endAlignment = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: const Alignment(1.0, 1.0),
          end: const Alignment(0.2, 1.0),
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: const Alignment(0.2, 1.0),
          end: const Alignment(1.0, 1.0),
        ),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      body: Stack(
        children: [
          // Animated gradient background
          if (widget.showBackgroundEffects)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _gradientController,
                builder: (context, _) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: _beginAlignment.value,
                        end: _endAlignment.value,
                        colors: isDark
                            ? [
                                const Color(0xFFDD0B0E).withValues(alpha: 0.18),
                                const Color(0xFF393532).withValues(alpha: 0.85),
                                const Color(0xFF1A1A2E).withValues(alpha: 0.6),
                              ]
                            : [
                                const Color(0xFFDD0B0E).withValues(alpha: 0.06),
                                cadife.background,
                                const Color(0xFF393532).withValues(alpha: 0.04),
                              ],
                      ),
                    ),
                  );
                },
              ),
            ),
          // Subtle glow orbs (dark mode only)
          if (widget.showBackgroundEffects && isDark) ...[
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
              ).animate().fadeIn(duration: 800.ms),
            ),
            Positioned(
              bottom: 120,
              left: -80,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withValues(alpha: 0.04),
                ),
              ).animate().fadeIn(duration: 1200.ms),
            ),
          ],
          content,
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: widget.bottomNavigationBar,
    );
  }
}
