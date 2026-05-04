import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';

class HistoricoShimmer extends StatelessWidget {
  const HistoricoShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      isLoading: true,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 72, bottom: 96, left: 16, right: 16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return const Column(
            children: [
        Skeleton(
                height: 180,
                borderRadius: 24,
              ),
        SizedBox(height: 12),
        Row(
                children: [
                  Expanded(child: Skeleton(height: 14)),
                  SizedBox(width: 16),
                  Expanded(child: Skeleton(height: 14)),
                ],
              ),
        SizedBox(height: 8),
        Row(
                children: [
                  Expanded(child: Skeleton(height: 14)),
                  SizedBox(width: 16),
                  Expanded(child: Skeleton(height: 14)),
                ],
              ),
        SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class HistoricoEmptyState extends StatelessWidget {
  const HistoricoEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.plane,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhuma viagem encontrada',
              textAlign: TextAlign.center,
              style: context.shadText.h4.copyWith(
                color: context.cadife.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Suas últimas aventuras concluídas aparecerão aqui para você relembrar.',
              textAlign: TextAlign.center,
              style: context.shadText.muted.copyWith(
                color: context.cadife.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoricoErrorState extends StatelessWidget {
  const HistoricoErrorState({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: context.cadife.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Não foi possível carregar o histórico.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.cadife.textPrimary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ShadButton(
              onPressed: onRetry,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
