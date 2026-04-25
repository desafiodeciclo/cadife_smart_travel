import 'package:cadife_smart_travel/features/auth/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Wait for the animation to show at least for 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    
    final auth = ref.read(authProvider.notifier);
    await auth.checkSession();
    
    if (mounted) {
      final authState = ref.read(authProvider);
      if (authState.isLoggedIn) {
        final target = authState.userPerfil == 'agencia'
            ? '/agency/dashboard'
            : '/client/status';
        context.go(target);
      } else {
        context.go('/auth/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/splash.json',
              width: 200,
              height: 200,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.travel_explore, size: 100, color: Colors.blue);
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Cadife Smart Travel',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            const CircularProgressIndicator.adaptive(),
          ],
        ),
      ),
    );
  }
}
