import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';

class HistoricoShimmer extends StatelessWidget {
  const HistoricoShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      isLoading: true,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 16, bottom: 96),
        itemCount: 9,
        itemBuilder: (context, index) {
          final isRight = index % 3 == 0;
          final showDivider = index == 0 || index == 4;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showDivider)
                const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Skeleton(height: 1)),
                      SizedBox(width: 12),
                      Skeleton(width: 64, height: 11),
                      SizedBox(width: 12),
                      Expanded(child: Skeleton(height: 1)),
                    ],
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(
                  left: isRight ? 56 : 16,
                  right: isRight ? 16 : 56,
                  bottom: 14,
                ),
                child: Column(
                  crossAxisAlignment:
                      isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!isRight) ...[
                      const Skeleton(width: 100, height: 11),
                      const SizedBox(height: 4),
                    ],
                    Skeleton(
                      height: index.isEven ? 60 : 40,
                      borderRadius: 16,
                    ),
                    const SizedBox(height: 4),
                    const Skeleton(width: 72, height: 10),
                  ],
                ),
              ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sua conversa com a AYA aparecerá aqui',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.cadife.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Inicie um atendimento pelo WhatsApp para ver o histórico.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: context.cadife.textSecondary,
                height: 1.5,
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
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
