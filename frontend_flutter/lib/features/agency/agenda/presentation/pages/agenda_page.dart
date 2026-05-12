import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/agenda/domain/entities/agendamento.dart';
import 'package:cadife_smart_travel/features/agency/agenda/presentation/providers/agenda_provider.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/providers/leads_notifier.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/state_container.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

part 'agenda_month_view.dart';
part 'agenda_daily_view.dart';
part 'agenda_lead_summary.dart';

// ─── Connectivity provider ────────────────────────────────────────────────────

final _connectivityProvider =
    StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

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
    final connectivity = ref.watch(_connectivityProvider);

    final isOffline = connectivity.whenOrNull(
          data: (results) =>
              !results.contains(ConnectivityResult.mobile) &&
              !results.contains(ConnectivityResult.wifi) &&
              !results.contains(ConnectivityResult.ethernet),
        ) ??
        false;

    return PageScaffold(
      appBar: CadifeAppBar(
        title: 'Agenda',
        actions: [
          if (isOffline)
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off, size: 12, color: AppColors.warning),
                  SizedBox(width: 4),
                  Text(
                    'Offline',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(agendaProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: viewMode == 1
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Nova reunião',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                final selectedDate = ref.read(selectedAgendaDateProvider);
                final now = DateTime.now();
                final defaultHour =
                    selectedDate.day == now.day ? now.hour.clamp(9, 15) : 9;
                final slotStart = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  defaultHour,
                );
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _LeadSelectSheet(slotStart: slotStart),
                );
              },
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
