import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/itinerary/domain/entities/itinerary_item.dart';
import 'package:cadife_smart_travel/features/client/itinerary/presentation/widgets/daily_note_field.dart';
import 'package:cadife_smart_travel/features/client/itinerary/presentation/widgets/itinerary_card.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class DailyItineraryView extends StatefulWidget {
  const DailyItineraryView({
    required this.selectedDate,
    required this.itemsForDay,
    required this.onDateChanged,
    required this.onSaveNote,
    required this.initialNote,
    super.key,
    this.isLoading = false,
  });

  final DateTime selectedDate;
  final List<ItineraryItem> itemsForDay;
  final void Function(DateTime) onDateChanged;
  final Future<void> Function(String) onSaveNote;
  final String? initialNote;
  final bool isLoading;

  @override
  State<DailyItineraryView> createState() => _DailyItineraryViewState();
}

class _DailyItineraryViewState extends State<DailyItineraryView> {
  static const _startHour = 6;
  static const _endHour = 23;

  void _previousDay() {
    widget.onDateChanged(
      widget.selectedDate.subtract(const Duration(days: 1)),
    );
  }

  void _nextDay() {
    widget.onDateChanged(
      widget.selectedDate.add(const Duration(days: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > 200) _previousDay();
        if (velocity < -200) _nextDay();
      },
      child: Column(
        children: [
          _DateNavigator(
            date: widget.selectedDate,
            onPrevious: _previousDay,
            onNext: _nextDay,
          ),
          Expanded(
            child: widget.isLoading
                ? _TimelineShimmer()
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTimeline(),
                        const SizedBox(height: 24),
                        DailyNoteField(
                          key: ValueKey(widget.selectedDate.toIso8601String()),
                          initialNote: widget.initialNote,
                          onSave: widget.onSaveNote,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    if (widget.itemsForDay.isEmpty) {
      return _EmptyDayState();
    }

    final grouped = _groupByHour(widget.itemsForDay);
    final rows = <Widget>[];

    for (var hour = _startHour; hour <= _endHour; hour++) {
      final items = grouped[hour] ?? [];
      rows.add(_TimelineHourRow(hour: hour, items: items));
    }

    return Column(children: rows);
  }

  Map<int, List<ItineraryItem>> _groupByHour(List<ItineraryItem> items) {
    final map = <int, List<ItineraryItem>>{};
    for (final item in items) {
      final hour = item.dataHora.toLocal().hour;
      (map[hour] ??= []).add(item);
    }
    return map;
  }
}

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({
    required this.date,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime date;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final label = DateFormat("d 'de' MMMM", 'pt_BR').format(date);
    final weekday = DateFormat('EEEE', 'pt_BR').format(date);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cadife.cardBorder),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(LucideIcons.chevronLeft, size: 20, color: cadife.textPrimary),
            onPressed: onPrevious,
            tooltip: 'Dia anterior',
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cadife.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  _capitalize(weekday),
                  style: TextStyle(
                    fontSize: 12,
                    color: cadife.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(LucideIcons.chevronRight, size: 20, color: cadife.textPrimary),
            onPressed: onNext,
            tooltip: 'Próximo dia',
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;
}

class _TimelineHourRow extends StatelessWidget {
  const _TimelineHourRow({required this.hour, required this.items});

  final int hour;
  final List<ItineraryItem> items;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final hasItems = items.isNotEmpty;
    final hourLabel = '${hour.toString().padLeft(2, '0')}:00';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hora
          SizedBox(
            width: 44,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                hourLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: hasItems ? cadife.textPrimary : cadife.cardBorder,
                  fontWeight: hasItems ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Linha vertical
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasItems ? cadife.primary : cadife.cardBorder,
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: cadife.cardBorder,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Eventos
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 4),
              child: hasItems
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: items
                          .map((item) => ItineraryCard(item: item))
                          .toList(),
                    )
                  : const SizedBox(height: 28),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDayState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(
              LucideIcons.calendarX2,
              size: 48,
              color: cadife.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'Sem atividades neste dia',
              style: TextStyle(
                fontSize: 14,
                color: cadife.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Seu itinerário aparecerá após a curadoria',
              style: TextStyle(fontSize: 12, color: cadife.textSecondary.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (_, _) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
