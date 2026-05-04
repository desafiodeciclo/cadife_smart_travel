import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/auth/providers/auth_provider.dart';
import 'package:cadife_smart_travel/features/client/status/presentation/providers/status_notifier.dart';
import 'package:cadife_smart_travel/features/client/status/presentation/widgets/status_stepper_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StatusPage extends ConsumerWidget {
  const StatusPage({super.key});

  static const _steps = [
    'Em análise',
    'Proposta enviada',
    'Confirmado',
    'Emitido',
  ];

  int _mapStatusToStep(LeadStatus? status) {
    if (status == null) return 0;
    switch (status) {
      case LeadStatus.novo:
      case LeadStatus.emAtendimento:
      case LeadStatus.qualificado:
      case LeadStatus.agendado:
        return 0;
      case LeadStatus.proposta:
        return 1;
      case LeadStatus.fechado:
        return 2;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    // Para simplificar, pegamos o ID do usuário logado se for cliente.
    final userId = authState.value?.user?.id ?? '';
    
    final statusAsync = ref.watch(statusProvider(userId));

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
      body: statusAsync.when(
        data: (lead) {
          final currentStep = _mapStatusToStep(lead?.status);

          return RefreshIndicator(
            onRefresh: () => ref.read(statusProvider(userId).notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Olá, ${lead?.name ?? 'Viajante'}!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Status da sua viagem',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 32),
                ...List.generate(
                  _steps.length,
                  (i) => StatusStepperItem(
                    label: _steps[i],
                    isCompleted: i < currentStep,
                    isCurrent: i == currentStep,
                    isLast: i == _steps.length - 1,
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.history),
                        label: const Text('Histórico'),
                        onPressed: () => context.push('/client/historico'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.folder),
                        label: const Text('Documentos'),
                        onPressed: () => context.push('/client/documentos'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              const Text('Erro ao carregar status da viagem'),
              TextButton(
                onPressed: () => ref.read(statusProvider(userId).notifier).refresh(),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
