import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SlideTransitionPage<T> extends CustomTransitionPage<T> {
  SlideTransitionPage({
    required super.child,
    super.name,
    super.arguments,
    super.restorationId,
    super.key,
    this.transitionDuration = const Duration(milliseconds: 280),
    this.curve = Curves.easeInOut,
    this.reverse = false,
  }) : super(
          transitionDuration: transitionDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              _buildSlideTransition(
            animation,
            secondaryAnimation,
            child,
            transitionDuration,
            curve,
            reverse,
          ),
        );

  final Duration transitionDuration;
  final Curve curve;
  final bool reverse;

  static Widget _buildSlideTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
    Duration duration,
    Curve curve,
    bool reverse,
  ) {
    final beginOffset = reverse
        ? const Offset(1.0, 0.0) // slide esquerda (back)
        : const Offset(-1.0, 0.0); // slide direita (forward)

    return SlideTransition(
      position: animation.drive(
        Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).chain(CurveTween(curve: curve)),
      ),
      child: SlideTransition(
        position: secondaryAnimation.drive(
          Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(1.0, 0.0),
          ).chain(CurveTween(curve: Curves.easeOut)),
        ),
        child: child,
      ),
    );
  }
}

// Modal variant
class ModalSlideTransitionPage<T> extends CustomTransitionPage<T> {
  ModalSlideTransitionPage({
    required super.child,
    super.name,
    super.arguments,
    super.restorationId,
    super.key,
    this.transitionDuration = const Duration(milliseconds: 300),
  }) : super(
          transitionDuration: transitionDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
            position: animation.drive(
              Tween<Offset>(
                begin: const Offset(0.0, 1.0), // slide de baixo
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOut)),
            ),
            child: ScaleTransition(
              scale: animation.drive(
                Tween<double>(begin: 0.95, end: 1.0)
                    .chain(CurveTween(curve: Curves.easeOut)),
              ),
              child: child,
            ),
          ),
        );

  final Duration transitionDuration;
}
