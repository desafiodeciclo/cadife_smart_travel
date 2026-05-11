import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/itinerary/domain/entities/itinerary_item.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class MonthlyCalendarView extends StatefulWidget {
  const MonthlyCalendarView({
    required this.itemsByDay,
    required this.selectedDay,
    required this.onDaySelected,
    super.key,
    this.focusedDay,
  });

  final Map<DateTime, List<ItineraryItem>> itemsByDay;
  final DateTime selectedDay;
  final DateTime? focusedDay;
  final void Function(DateTime selected, DateTime focused) onDaySelected;

  @override
  State<MonthlyCalendarView> createState() => _MonthlyCalendarViewState();
}

class _MonthlyCalendarViewState extends State<MonthlyCalendarView> {
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.focusedDay ?? widget.selectedDay;
  }

  List<ItineraryItem> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return widget.itemsByDay[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;

    return Column(
      children: [
        TableCalendar<ItineraryItem>(
          firstDay: DateTime(2020),
          lastDay: DateTime(2035),
          focusedDay: _focusedDay,
          locale: 'pt_BR',
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {CalendarFormat.month: 'Mês'},
          selectedDayPredicate: (day) => isSameDay(widget.selectedDay, day),
          onDaySelected: (selected, focused) {
            setState(() => _focusedDay = focused);
            widget.onDaySelected(selected, focused);
          },
          onPageChanged: (focused) {
            setState(() => _focusedDay = focused);
          },
          eventLoader: _getEventsForDay,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cadife.textPrimary,
            ),
            leftChevronIcon: Icon(
              Icons.chevron_left,
              color: cadife.textPrimary,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right,
              color: cadife.textPrimary,
            ),
            headerPadding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: cadife.background),
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: true,
            outsideTextStyle: TextStyle(
              color: cadife.textSecondary.withValues(alpha: 0.4),
              fontSize: 13,
            ),
            defaultTextStyle: TextStyle(
              color: cadife.textPrimary,
              fontSize: 13,
            ),
            weekendTextStyle: TextStyle(
              color: cadife.textSecondary,
              fontSize: 13,
            ),
            selectedDecoration: BoxDecoration(
              color: cadife.primary,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            todayDecoration: BoxDecoration(
              color: cadife.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            todayTextStyle: TextStyle(
              color: cadife.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            rowDecoration: BoxDecoration(color: cadife.background),
            markerDecoration: const BoxDecoration(shape: BoxShape.circle),
            markersMaxCount: 4,
            markersAlignment: Alignment.bottomCenter,
            tableBorder: TableBorder(
              horizontalInside: BorderSide(
                color: cadife.cardBorder,
                width: 0.5,
              ),
            ),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              color: cadife.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            weekendStyle: TextStyle(
              color: cadife.textSecondary.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            decoration: BoxDecoration(color: cadife.background),
          ),
          calendarBuilders: CalendarBuilders<ItineraryItem>(
            markerBuilder: (context, day, events) {
              if (events.isEmpty) return const SizedBox.shrink();
              final unique = _uniqueTypes(events);
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: unique
                      .take(4)
                      .map(
                        (type) => Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: type.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                      .toList(),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _EventTypeLegend(),
      ],
    );
  }

  List<ItineraryItemType> _uniqueTypes(List<ItineraryItem> items) {
    final seen = <ItineraryItemType>{};
    return items.map((e) => e.tipo).where(seen.add).toList();
  }
}

class _EventTypeLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    const types = ItineraryItemType.values;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: types
            .map(
              (type) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: type.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    type.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: cadife.textSecondary,
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
