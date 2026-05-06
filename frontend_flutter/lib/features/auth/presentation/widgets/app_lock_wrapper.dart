import 'package:cadife_smart_travel/features/auth/presentation/screens/app_lock_screen.dart';
import 'package:cadife_smart_travel/features/auth/providers/app_lock_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Observa o lifecycle do app e exibe [AppLockScreen] quando o tempo em
/// background ultrapassa AppConstants.appLockTimeout.
///
/// Deve ser usado como builder de MaterialApp.router para ficar acima
/// da navegação e herdar Theme / MediaQuery.
class AppLockWrapper extends ConsumerStatefulWidget {
  const AppLockWrapper({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends ConsumerState<AppLockWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    switch (lifecycle) {
      case AppLifecycleState.paused:
        ref.read(appLockProvider.notifier).onAppPaused();
      case AppLifecycleState.resumed:
        ref.read(appLockProvider.notifier).onAppResumed();
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(appLockProvider).isLocked;
    return Stack(
      children: [
        widget.child,
        if (isLocked) const AppLockScreen(),
      ],
    );
  }
}
