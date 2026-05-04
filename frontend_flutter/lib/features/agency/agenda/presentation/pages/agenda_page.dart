import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/agenda/domain/entities/agendamento.dart';
import 'package:cadife_smart_travel/features/agency/agenda/presentation/providers/agenda_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

part 'agenda_month_view.dart';
part 'agenda_daily_view.dart';

// ─── Localisation helpers ─────────────────────────────────────────────────────

const _meses = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];
const _diasSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

String _monthLabel(DateTime d) => '${_meses[d.month - 1]} ${d.year}';

// ─── Screen ───────────────────────────────────────────────────────────────────

class AgendaScreen extends ConsumerWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(agendaViewModeProvider);
    final allAsync = ref.watch(agendaProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: CadifeAppBar(
        title: 'Agenda',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(agendaProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          _ViewToggleBar(viewMode: viewMode),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: allAsync.when(
              loading: () => ShimmerLoading(
                isLoading: true,
                child: AppSkeletons.listPage(),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text('Erro: $e'),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          ref.read(agendaProvider.notifier).refresh(),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
              data: (items) => viewMode == 0
                  ? _MonthView(items: items)
                  : _DailyView(items: items),
            ),
          ),
        ],
      ),
      floatingActionButton: viewMode == 1
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Selecione um slot vazio na timeline para agendar.'),
                ),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Novo agendamento',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }
}

// ─── View toggle ──────────────────────────────────────────────────────────────

class _ViewToggleBar extends ConsumerWidget {
  const _ViewToggleBar({required this.viewMode});
  final int viewMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _ToggleChip(
            label: 'Mês',
            icon: Icons.calendar_month,
            selected: viewMode == 0,
            onTap: () =>
                ref.read(agendaViewModeProvider.notifier).state = 0,
          ),
          const SizedBox(width: 8),
          _ToggleChip(
            label: 'Dia',
            icon: Icons.view_day,
            selected: viewMode == 1,
            onTap: () =>
                ref.read(agendaViewModeProvider.notifier).state = 1,
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
