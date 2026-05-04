import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/agenda/agenda_provider.dart';
import 'package:cadife_smart_travel/features/agency/agenda/domain/entities/agendamento.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// â”€â”€â”€ Localisation helpers (no locale init needed) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

const _meses = [
  'Janeiro', 'Fevereiro', 'MarÃ§o', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];
const _diasSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'SÃ¡b', 'Dom'];

String _monthLabel(DateTime d) => '${_meses[d.month - 1]} ${d.year}';

// â”€â”€â”€ Screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class AgendaScreen extends ConsumerWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(agendaViewModeProvider);
    final allAsync = ref.watch(agendaProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.scaffold,
        elevation: 0,
        title: const Text(
          'Agenda',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
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
                    const Text('Erro ao carregar agenda.'),
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
                  content: Text('Selecione um slot vazio na timeline para agendar.'),
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

// â”€â”€â”€ View toggle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
            label: 'MÃªs',
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

// â”€â”€â”€ Monthly view â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MonthView extends ConsumerWidget {
  const _MonthView({required this.items});
  final List<Agendamento> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedAgendaDateProvider);
    final currentMonth = DateTime(selected.year, selected.month, 1);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MonthNavBar(currentMonth: currentMonth),
          const SizedBox(height: 8),
          _WeekdayHeader(),
          const SizedBox(height: 4),
          _CalendarGrid(
            currentMonth: currentMonth,
            selectedDate: selected,
            items: items,
          ),
          const SizedBox(height: 16),
          _DensityLegend(),
        ],
      ),
    );
  }
}

class _MonthNavBar extends ConsumerWidget {
  const _MonthNavBar({required this.currentMonth});
  final DateTime currentMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          color: AppColors.textPrimary,
          onPressed: () {
            final d = ref.read(selectedAgendaDateProvider);
            ref.read(selectedAgendaDateProvider.notifier).state =
                DateTime(d.year, d.month - 1, 1);
          },
        ),
        Expanded(
          child: Text(
            _monthLabel(currentMonth),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          color: AppColors.textPrimary,
          onPressed: () {
            final d = ref.read(selectedAgendaDateProvider);
            ref.read(selectedAgendaDateProvider.notifier).state =
                DateTime(d.year, d.month + 1, 1);
          },
        ),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: _diasSemana
          .map(
            (d) => Expanded(
              child: Text(
                d,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CalendarGrid extends ConsumerWidget {
  const _CalendarGrid({
    required this.currentMonth,
    required this.selectedDate,
    required this.items,
  });

  final DateTime currentMonth;
  final DateTime selectedDate;
  final List<Agendamento> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstDay = currentMonth;
    final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    // DateTime.weekday: 1=Mon â€¦ 7=Sun â†’ offset for Mon-first grid
    final startOffset = firstDay.weekday - 1;

    final cells = <Widget>[];

    for (int i = 0; i < startOffset; i++) {
      cells.add(const SizedBox());
    }

    final now = DateTime.now();

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(currentMonth.year, currentMonth.month, day);
      final meetingCount = items
          .where(
            (a) =>
                a.dateTime.year == date.year &&
                a.dateTime.month == date.month &&
                a.dateTime.day == date.day &&
                a.status != 'bloqueado' &&
                a.status != 'cancelado',
          )
          .length;

      final isToday = date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
      final isSelected = date.year == selectedDate.year &&
          date.month == selectedDate.month &&
          date.day == selectedDate.day;

      cells.add(
        _DayCell(
          day: day,
          date: date,
          meetingCount: meetingCount,
          isToday: isToday,
          isSelected: isSelected,
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.9,
      children: cells,
    );
  }
}

class _DayCell extends ConsumerWidget {
  const _DayCell({
    required this.day,
    required this.date,
    required this.meetingCount,
    required this.isToday,
    required this.isSelected,
  });

  final int day;
  final DateTime date;
  final int meetingCount;
  final bool isToday;
  final bool isSelected;

  Color? get _dotColor {
    if (meetingCount == 0) return null;
    if (meetingCount >= 5) return AppColors.primary;
    if (meetingCount >= 3) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bgColor = isSelected
        ? AppColors.primary
        : isToday
            ? AppColors.primaryLight
            : null;

    final textColor = isSelected
        ? Colors.white
        : isToday
            ? AppColors.primary
            : AppColors.textPrimary;

    return GestureDetector(
      onTap: () {
        ref.read(selectedAgendaDateProvider.notifier).state = date;
        ref.read(agendaViewModeProvider.notifier).state = 1;
      },
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day.toString(),
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                color: textColor,
              ),
            ),
            if (_dotColor != null) ...[
              const SizedBox(height: 2),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.9)
                      : _dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DensityLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _LegendItem(color: AppColors.success, label: '1â€“2 reuniÃµes'),
        _LegendItem(color: AppColors.warning, label: '3â€“4 reuniÃµes'),
        _LegendItem(color: AppColors.primary, label: '5+ reuniÃµes'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

// â”€â”€â”€ Daily view â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _DailyView extends ConsumerWidget {
  const _DailyView({required this.items});
  final List<Agendamento> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedAgendaDateProvider);

    final dayItems = items
        .where(
          (a) =>
              a.dateTime.year == selectedDate.year &&
              a.dateTime.month == selectedDate.month &&
              a.dateTime.day == selectedDate.day,
        )
        .toList();

    return Column(
      children: [
        _DayNavBar(selectedDate: selectedDate),
        const Divider(height: 1, color: AppColors.divider),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: 7, // slots 09:00 â†’ 15:00
            itemBuilder: (context, index) {
              final hour = 9 + index;
              final slotStart = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                hour,
              );

              final matching = dayItems.where((a) => a.dateTime.hour == hour);
              final meeting = matching.isEmpty ? null : matching.first;

              return _TimeSlotRow(
                hour: hour,
                slotStart: slotStart,
                meeting: meeting,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DayNavBar extends ConsumerWidget {
  const _DayNavBar({required this.selectedDate});
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayLabel =
        '${selectedDate.day.toString().padLeft(2, '0')} de ${_meses[selectedDate.month - 1]}, ${selectedDate.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: AppColors.textPrimary,
            onPressed: () {
              final d = ref.read(selectedAgendaDateProvider);
              ref.read(selectedAgendaDateProvider.notifier).state =
                  d.subtract(const Duration(days: 1));
            },
          ),
          Expanded(
            child: Text(
              dayLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: AppColors.textPrimary,
            onPressed: () {
              final d = ref.read(selectedAgendaDateProvider);
              ref.read(selectedAgendaDateProvider.notifier).state =
                  d.add(const Duration(days: 1));
            },
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Time slot row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TimeSlotRow extends StatelessWidget {
  const _TimeSlotRow({
    required this.hour,
    required this.slotStart,
    required this.meeting,
  });

  final int hour;
  final DateTime slotStart;
  final Agendamento? meeting;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time label column
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Text(
                  '${hour.toString().padLeft(2, '0')}:00',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      width: 1,
                      color: AppColors.divider,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Slot content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildSlotContent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotContent(BuildContext context) {
    if (meeting == null) {
      return _EmptySlotCard(slotStart: slotStart);
    }
    if (meeting!.status == 'bloqueado') {
      return _BlockedSlotCard(meeting: meeting!);
    }
    return _MeetingCard(meeting: meeting!);
  }
}

// â”€â”€â”€ Meeting card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MeetingCard extends StatelessWidget {
  const _MeetingCard({required this.meeting});
  final Agendamento meeting;

  @override
  Widget build(BuildContext context) {
    final endTime =
        meeting.dateTime.add(Duration(minutes: meeting.durationMinutes));
    final timeRange =
        '${DateFormat('HH:mm').format(meeting.dateTime)} â€“ ${DateFormat('HH:mm').format(endTime)}';
    final displayName = meeting.notes?.isNotEmpty == true ? meeting.notes! : 'ReuniÃ£o de Curadoria';

    return Material(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: meeting.leadId.isNotEmpty
            ? () => context.push('/agency/leads/${meeting.leadId}')
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: const Border(
              left: BorderSide(color: AppColors.primary, width: 3),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      timeRange,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(status: meeting.status),
              if (meeting.leadId.isNotEmpty) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status.toLowerCase()) {
      'agendado' => ('Agendado', AppColors.info),
      'realizado' => ('Realizado', AppColors.success),
      'cancelado' => ('Cancelado', AppColors.textSecondary),
      _ => (status, AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// â”€â”€â”€ Blocked slot card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _BlockedSlotCard extends ConsumerWidget {
  const _BlockedSlotCard({required this.meeting});
  final Agendamento meeting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label =
        meeting.notes?.isNotEmpty == true ? meeting.notes! : 'HorÃ¡rio Bloqueado';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.lock_open, size: 18),
            color: AppColors.warning,
            tooltip: 'Desbloquear',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _confirmUnblock(context, ref, meeting),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmUnblock(
    BuildContext context,
    WidgetRef ref,
    Agendamento m,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Desbloquear horÃ¡rio?'),
        content: Text(
          'Deseja liberar ${DateFormat('HH:mm').format(m.dateTime)} para agendamentos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Desbloquear'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(agendaProvider.notifier).unblockSlot(m.id);
    }
  }
}

// â”€â”€â”€ Empty slot card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _EmptySlotCard extends ConsumerWidget {
  const _EmptySlotCard({required this.slotStart});
  final DateTime slotStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showSlotOptions(context, ref, slotStart),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.scaffold,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text(
            'DisponÃ­vel  Â·  Toque para agendar ou bloquear',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  void _showSlotOptions(BuildContext context, WidgetRef ref, DateTime slot) {
    final notifier = ref.read(agendaProvider.notifier);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => _SlotOptionsSheet(
        slotStart: slot,
        onSchedule: () {
          Navigator.of(sheetContext).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Selecione um lead e agende para ${DateFormat('HH:mm').format(slot)}.',
              ),
            ),
          );
        },
        onBlock: (notes) async {
          Navigator.of(sheetContext).pop();
          await notifier.blockSlot(slot, notes: notes);
        },
      ),
    );
  }
}

// â”€â”€â”€ Slot options bottom sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SlotOptionsSheet extends StatefulWidget {
  const _SlotOptionsSheet({
    required this.slotStart,
    required this.onSchedule,
    required this.onBlock,
  });

  final DateTime slotStart;
  final VoidCallback onSchedule;
  final Future<void> Function(String? notes) onBlock;

  @override
  State<_SlotOptionsSheet> createState() => _SlotOptionsSheetState();
}

class _SlotOptionsSheetState extends State<_SlotOptionsSheet> {
  final _notesController = TextEditingController();
  bool _showNotesField = false;
  bool _isBlocking = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(widget.slotStart);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'HorÃ¡rio $timeStr',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'O que deseja fazer com este horÃ¡rio?',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          // Schedule option
          ListTile(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            tileColor: AppColors.primaryLight,
            leading: const Icon(Icons.event_available, color: AppColors.primary),
            title: const Text(
              'Agendar ReuniÃ£o',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Vincular a um lead existente'),
            onTap: widget.onSchedule,
          ),
          const SizedBox(height: 8),
          // Block option
          ListTile(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            tileColor: AppColors.surface,
            leading:
                const Icon(Icons.do_not_disturb_on, color: AppColors.warning),
            title: const Text(
              'Bloquear HorÃ¡rio',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Pausa ou reuniÃ£o interna'),
            trailing: _showNotesField
                ? null
                : const Icon(Icons.expand_more, color: AppColors.textSecondary),
            onTap: () => setState(() => _showNotesField = true),
          ),
          if (_showNotesField) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              autofocus: true,
              maxLength: 80,
              decoration: InputDecoration(
                hintText: 'Motivo (opcional)',
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isBlocking
                    ? null
                    : () async {
                        setState(() => _isBlocking = true);
                        await widget.onBlock(_notesController.text.trim().isEmpty
                            ? null
                            : _notesController.text.trim());
                      },
                child: _isBlocking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Confirmar Bloqueio'),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}



