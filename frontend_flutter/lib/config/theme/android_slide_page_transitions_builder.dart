import 'package:flutter/material.dart';

class AndroidSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Detectar direção da navegação via route metadata
    final isGoingBack = route.settings.name?.contains('pop') ?? false;
    final beginOffset = isGoingBack
        ? const Offset(1.0, 0.0)  // slide da esquerda (retorno)
        : const Offset(-1.0, 0.0); // slide da direita (avanço)
    
    return SlideTransition(
      position: animation.drive(
        Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
      ),
      child: SlideTransition(
        position: secondaryAnimation.drive(
          Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(1.0, 0.0),
          ).chain(
            CurveTween(curve: Curves.easeOut),
          ),
        ),
        child: child,
      ),
    );
  }
}
