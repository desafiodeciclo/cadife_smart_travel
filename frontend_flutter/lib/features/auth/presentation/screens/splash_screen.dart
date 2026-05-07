import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cadife_smart_travel/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _animationDone = false;
  bool _validationDone = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    // Wait for authNotifierProvider.build() to complete (checks JWT on startup).
    WidgetsBinding.instance.addPostFrameCallback((_) => _startValidation());
  }

  Future<void> _startValidation() async {
    try {
      await ref.read(authNotifierProvider.future);
    } on Object catch (_) {
      // Auth check failed — treat as unauthenticated.
    }
    if (mounted) {
      setState(() => _validationDone = true);
      await _tryNavigate();
    }
  }

  void _onAnimationLoaded(LottieComposition composition) {
    _controller
      ..duration = composition.duration
      ..addStatusListener(_onAnimationStatus)
      ..forward();
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _animationDone = true);
      _tryNavigate();
    }
  }

  Future<void> _tryNavigate() async {
    if (!_animationDone || !_validationDone) return;
    if (!mounted) return;

    final authValue = ref.read(authNotifierProvider);
    final isLoggedIn = authValue.valueOrNull != null;

    if (!isLoggedIn) {
      final seen = await hasSeenOnboarding();
      if (!mounted) return;
      context.go(seen ? '/auth/login' : '/onboarding');
    } else {
      // GoRouter redirect routes to the correct home based on role.
      context.go('/auth/login');
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cadife.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: Lottie.asset(
                'assets/animations/splash.json',
                controller: _controller,
                onLoaded: _onAnimationLoaded,
                frameRate: FrameRate.max,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Cadife Smart Travel',
              style: AppTextStyles.h2.copyWith(color: AppColors.textOnDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Sua viagem começa aqui',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textOnDark.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
