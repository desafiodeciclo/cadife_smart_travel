import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/itinerary/presentation/providers/itinerary_provider.dart';
import 'package:cadife_smart_travel/features/client/itinerary/presentation/widgets/daily_itinerary_view.dart';
import 'package:cadife_smart_travel/features/client/itinerary/presentation/widgets/monthly_calendar_view.dart';
import 'package:cadife_smart_travel/features/client/itinerary/presentation/widgets/sync_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TravelCalendarPage extends ConsumerStatefulWidget {
  const TravelCalendarPage({required this.leadId, super.key});

  final String leadId;

  @override
  ConsumerState<TravelCalendarPage> createState() =>
      _TravelCalendarPageState();
}

class _TravelCalendarPageState extends ConsumerState<TravelCalendarPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itineraryProvider(widget.leadId));
    final notifier = ref.read(itineraryProvider(widget.leadId).notifier);
    final cadife = context.cadife;

    final selectedDate = state.selectedDate ?? DateTime.now();
    final isDaily = state.viewMode == CalendarViewMode.diaria;
    final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);

    return Scaffold(
      backgroundColor: cadife.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF393532),
        foregroundColor: Colors.white,
        title: const Text(
          'Meu Itinerário',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (state.isSyncing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              tooltip: 'Sincronizar',
              onPressed: () => notifier.syncItinerary(widget.leadId),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _ViewToggle(
            isDaily: isDaily,
            onChanged: ({required daily}) => notifier.setViewMode(
              daily ? CalendarViewMode.diaria : CalendarViewMode.mensal,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          SyncIndicator(
            isSyncing: state.isSyncing,
            isOffline: state.isOffline,
            lastSyncedAt: state.lastSyncedAt,
          ),
          if (state.error != null && state.items.isEmpty)
            _ErrorBanner(
              onRetry: () => notifier.loadItinerary(widget.leadId),
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: state.isLoading && state.items.isEmpty
                  ? const _LoadingPlaceholder(key: ValueKey('loading'))
                  : isDaily
                      ? DailyItineraryView(
                          key: ValueKey('daily_$dateKey'),
                          selectedDate: selectedDate,
                          itemsForDay: state.itemsForDay(selectedDate),
                          isLoading: state.isLoading,
                          initialNote:
                              notifier.getNote(widget.leadId, dateKey),
                          onDateChanged: notifier.selectDate,
                          onSaveNote: (nota) =>
                              notifier.saveNote(widget.leadId, dateKey, nota),
                        )
                      : _MonthlyWrapper(
                          key: const ValueKey('monthly'),
                          state: state,
                          notifier: notifier,
                          selectedDate: selectedDate,
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.isDaily, required this.onChanged});

  final bool isDaily;
  final void Function({required bool daily}) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF393532),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            _ToggleTab(
              label: 'Mensal',
              selected: !isDaily,
              onTap: () => onChanged(daily: false),
            ),
            _ToggleTab(
              label: 'Diária',
              selected: isDaily,
              onTap: () => onChanged(daily: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  const _ToggleTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected
                  ? const Color(0xFF393532)
                  : Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthlyWrapper extends StatelessWidget {
  const _MonthlyWrapper({
    required this.state,
    required this.notifier,
    required this.selectedDate,
    super.key,
  });

  final ItineraryState state;
  final ItineraryNotifier notifier;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    return state.items.isEmpty
        ? _EmptyItineraryState()
        : SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 8),
                MonthlyCalendarView(
                  itemsByDay: state.itemsByDay,
                  selectedDay: selectedDate,
                  onDaySelected: (selected, _) {
                    notifier.selectDate(selected, switchToDailyView: true);
                  },
                ).animate().fadeIn(duration: 200.ms),
                const SizedBox(height: 16),
              ],
            ),
          );
  }
}

class _EmptyItineraryState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.calendarDays,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'Seu itinerário será montado\napós a curadoria',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5D6D7E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quando o consultor montar seu roteiro,\nele aparecerá aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFFDD0B0E)),
          SizedBox(height: 16),
          Text(
            'Carregando itinerário...',
            style: TextStyle(fontSize: 14, color: Color(0xFF5D6D7E)),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: const Color(0xFFFFEAEA),
      child: Row(
        children: [
          const Icon(LucideIcons.circleAlert, size: 16, color: Color(0xFFDD0B0E)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Não foi possível carregar o itinerário.',
              style: TextStyle(fontSize: 13, color: Color(0xFFDD0B0E)),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: const Text(
              'Tentar novamente',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFFDD0B0E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
