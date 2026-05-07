import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AnimationType { forward, backward, modal }

class AnimationConfig {
  final Duration duration;
  final Curve curve;
  final AnimationType type;
  
  const AnimationConfig({
    required this.duration,
    required this.curve,
    required this.type,
  });
  
  factory AnimationConfig.forward() => const AnimationConfig(
    duration: Duration(milliseconds: 280),
    curve: Curves.easeInOut,
    type: AnimationType.forward,
  );
  
  factory AnimationConfig.backward() => const AnimationConfig(
    duration: Duration(milliseconds: 250),
    curve: Curves.easeOut,
    type: AnimationType.backward,
  );
  
  factory AnimationConfig.modal() => const AnimationConfig(
    duration: Duration(milliseconds: 300),
    curve: Curves.easeOut,
    type: AnimationType.modal,
  );
}

// Provider Riverpod
final animationConfigProvider = Provider<AnimationConfig>((ref) {
  // Por padrão, retorna forward. Lógica customizada pode ser injetada se necessário.
  return AnimationConfig.forward();
});
