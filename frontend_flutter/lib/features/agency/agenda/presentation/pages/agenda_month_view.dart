part of 'agenda_page.dart';

// ─── Monthly view ─────────────────────────────────────────────────────────────

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
    final daysInMonth =
        DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    // DateTime.weekday: 1=Mon … 7=Sun → offset for Mon-first grid
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
        _LegendItem(color: AppColors.success, label: '1–2 reuniões'),
        _LegendItem(color: AppColors.warning, label: '3–4 reuniões'),
        _LegendItem(color: AppColors.primary, label: '5+ reuniões'),
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
