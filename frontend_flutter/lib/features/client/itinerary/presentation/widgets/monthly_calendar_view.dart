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
          selectedDayPredicate: (day) =>
              isSameDay(widget.selectedDay, day),
          onDaySelected: (selected, focused) {
            setState(() => _focusedDay = focused);
            widget.onDaySelected(selected, focused);
          },
          onPageChanged: (focused) {
            setState(() => _focusedDay = focused);
          },
          eventLoader: _getEventsForDay,
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
            leftChevronIcon: Icon(
              Icons.chevron_left,
              color: Color(0xFF393532),
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right,
              color: Color(0xFF393532),
            ),
            headerPadding: EdgeInsets.symmetric(vertical: 8),
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            selectedDecoration: const BoxDecoration(
              color: Color(0xFFDD0B0E),
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: const Color(0xFFDD0B0E).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            todayTextStyle: const TextStyle(
              color: Color(0xFFDD0B0E),
              fontWeight: FontWeight.w600,
            ),
            weekendTextStyle: const TextStyle(color: Color(0xFF5D6D7E)),
            defaultTextStyle: const TextStyle(color: Color(0xFF1A1A1A)),
            markerDecoration: const BoxDecoration(shape: BoxShape.circle),
            markersMaxCount: 4,
            markersAlignment: Alignment.bottomCenter,
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
    return items
        .map((e) => e.tipo)
        .where(seen.add)
        .toList();
  }
}

class _EventTypeLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF5D6D7E),
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
