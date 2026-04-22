import 'package:cadife_smart_travel/core/theme/app_colors.dart';
import 'package:cadife_smart_travel/features/auth/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StatusScreen extends ConsumerWidget {
  const StatusScreen({super.key});

  static const _steps = [
    'Em análise',
    'Proposta enviada',
    'Confirmado',
    'Emitido',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const currentStep = 0; // Será dinâmico via API

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Viagem'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/auth/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status da sua viagem', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            ...List.generate(_steps.length, (i) => _StepItem(
                  label: _steps[i],
                  isCompleted: i < currentStep,
                  isCurrent: i == currentStep,
                  isLast: i == _steps.length - 1,
                )),
            const SizedBox(height: 24),
            Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text('Histórico'),
                  onPressed: () => context.push('/client/historico'),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.folder),
                  label: const Text('Documentos'),
                  onPressed: () => context.push('/client/documentos'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String label;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLast;
  const _StepItem({
    required this.label,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCompleted
        ? AppColors.success
        : isCurrent
            ? AppColors.primary
            : AppColors.textSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: color,
              child: Icon(
                isCompleted ? Icons.check : (isCurrent ? Icons.circle : Icons.radio_button_unchecked),
                size: 16,
                color: Colors.white,
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 32, color: isCompleted ? AppColors.success : AppColors.cardBackground),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
