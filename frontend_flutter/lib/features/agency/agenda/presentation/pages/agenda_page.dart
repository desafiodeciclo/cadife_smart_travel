import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/agenda/domain/entities/agendamento.dart';
import 'package:cadife_smart_travel/features/agency/agenda/presentation/providers/agenda_provider.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/state_container.dart';
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

    return PageScaffold(
      appBar: CadifeAppBar(
        title: 'Agenda',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(agendaProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: viewMode == 1
          ? CadifeButton(
              text: 'Novo agendamento',
              icon: Icons.add,
              analyticsLabel: 'agenda_new_appointment',
              onPressed: () => ShadToaster.of(context).show(
                const ShadToast(description: Text('Selecione um slot vazio na timeline para agendar.')),
              ),
            )
          : null,
      body: Column(
        children: [
          _ViewToggleBar(viewMode: viewMode),
          const Divider(height: 1),
          Expanded(
            child: StateContainer<List<Agendamento>>(
              state: allAsync,
              onRetry: () => ref.read(agendaProvider.notifier).refresh(),
              loadingWidget: ShimmerLoading(
                isLoading: true,
                child: AppSkeletons.listPage(),
              ),
              dataBuilder: (items) => AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.02, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: viewMode == 0
                    ? _MonthView(key: const ValueKey('month_view'), items: items)
                    : _DailyView(key: const ValueKey('day_view'), items: items),
              ),
            ),
          ),
        ],
      ),
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
      child: ShadTabs<int>(
        value: viewMode,
        onChanged: (v) => ref.read(agendaViewModeProvider.notifier).state = v,
        tabs: [
          const ShadTab(
            value: 0,
            content: SizedBox.shrink(),
            child: Text('Mês'),
          ),
          const ShadTab(
            value: 1,
            content: SizedBox.shrink(),
            child: Text('Dia'),
          ),
        ],
      ),
    );
  }
}
