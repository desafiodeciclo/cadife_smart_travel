import 'package:flutter/material.dart';

class AnimatedTabContent extends StatelessWidget {
  final Widget child;
  final int tabIndex;
  
  const AnimatedTabContent({
    super.key,
    required this.child,
    required this.tabIndex,
  });
  
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.1, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: child,
      key: ValueKey(tabIndex), // Force rebuild ao mudar aba
    );
  }
}
