import 'package:cadife_smart_travel/core/theme/app_colors.dart';
import 'package:cadife_smart_travel/core/theme/app_text_styles.dart';
import 'package:cadife_smart_travel/features/auth/providers/app_lock_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppLockScreen extends ConsumerWidget {
  const AppLockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lock = ref.watch(appLockProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 40,
                    color: AppColors.textOnPrimary,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Confirmar identidade',
                  style: AppTextStyles.h2.copyWith(color: AppColors.textOnDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'O app ficou inativo. Use biometria ou PIN para continuar.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textOnDark.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                if (lock.isLockedOut)
                  _LockedOutBanner()
                else ...[
                  if (lock.failures > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Tentativa ${lock.failures}/${lock.failures + (3 - lock.failures)} falhou. '
                        'Restam ${3 - lock.failures} tentativa(s).',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.warning,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          ref.read(appLockProvider.notifier).authenticate(),
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: const Text('Usar biometria / PIN'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: AppTextStyles.button,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LockedOutBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.block_rounded, color: AppColors.error, size: 48),
        const SizedBox(height: 16),
        Text(
          'Biometria bloqueada pelo sistema.\nAguarde e tente novamente.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
