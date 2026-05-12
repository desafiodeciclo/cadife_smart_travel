import 'dart:ui';

import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/itinerary/presentation/providers/itinerary_provider.dart';
import 'package:cadife_smart_travel/features/client/itinerary/presentation/widgets/daily_itinerary_view.dart';
import 'package:cadife_smart_travel/features/client/itinerary/presentation/widgets/monthly_calendar_view.dart';
import 'package:cadife_smart_travel/features/client/itinerary/presentation/widgets/sync_indicator.dart';
import 'package:cadife_smart_travel/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TravelCalendarPage extends ConsumerStatefulWidget {
  const TravelCalendarPage({required this.tripId, super.key});

  final String tripId;

  @override
  ConsumerState<TravelCalendarPage> createState() =>
      _TravelCalendarPageState();
}

class _TravelCalendarPageState extends ConsumerState<TravelCalendarPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itineraryProvider(widget.tripId));
    final notifier = ref.read(itineraryProvider(widget.tripId).notifier);
    final cadife = context.cadife;

    final selectedDate = state.selectedDate ?? DateTime.now();
    final isDaily = state.viewMode == CalendarViewMode.diaria;
    final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);

    return Scaffold(
      backgroundColor: cadife.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: cadife.background.withValues(alpha: 0.85),
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: cadife.textPrimary),
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
        title: Text(
          'MEU ITINERÁRIO',
          style: TextStyle(
            color: cadife.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          const NotificationBell(),
          if (state.isSyncing)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cadife.primary,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(LucideIcons.refreshCw, size: 18, color: cadife.textPrimary),
              tooltip: 'Sincronizar',
              onPressed: () => notifier.syncItinerary(widget.tripId),
            ),
        ],
      ),
      body: Column(
        children: [
          // Espaço para a AppBar transparente
          SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),

          // Toggle mensal / diária
          _ViewToggle(
            isDaily: isDaily,
            onChanged: ({required daily}) => notifier.setViewMode(
              daily ? CalendarViewMode.diaria : CalendarViewMode.mensal,
            ),
          ),

          SyncIndicator(
            isSyncing: state.isSyncing,
            isOffline: state.isOffline,
            lastSyncedAt: state.lastSyncedAt,
          ),

          if (state.error != null && state.items.isEmpty)
            _ErrorBanner(
              onRetry: () => notifier.loadItinerary(widget.tripId),
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
                              notifier.getNote(widget.tripId, dateKey),
                          onDateChanged: notifier.selectDate,
                          onSaveNote: (nota) =>
                              notifier.saveNote(widget.tripId, dateKey, nota),
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

// ─── Toggle mensal / diária ───────────────────────────────────────────────────

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.isDaily, required this.onChanged});

  final bool isDaily;
  final void Function({required bool daily}) onChanged;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: cadife.muted,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cadife.cardBorder),
        ),
        child: Row(
          children: [
            _ToggleTab(
              label: 'Mensal',
              selected: !isDaily,
              selectedColor: cadife.primary,
              textColor: cadife.textPrimary,
              mutedTextColor: cadife.textSecondary,
              onTap: () => onChanged(daily: false),
            ),
            _ToggleTab(
              label: 'Diária',
              selected: isDaily,
              selectedColor: cadife.primary,
              textColor: cadife.textPrimary,
              mutedTextColor: cadife.textSecondary,
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
    required this.selectedColor,
    required this.textColor,
    required this.mutedTextColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final Color textColor;
  final Color mutedTextColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: selected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : mutedTextColor,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Monthly wrapper ──────────────────────────────────────────────────────────

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

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyItineraryState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.calendarDays,
              size: 64,
              color: cadife.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Seu itinerário será montado\napós a curadoria',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cadife.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quando o consultor montar seu roteiro,\nele aparecerá aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cadife.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Loading placeholder ──────────────────────────────────────────────────────

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: cadife.primary),
          const SizedBox(height: 16),
          Text(
            'Carregando itinerário...',
            style: TextStyle(fontSize: 14, color: cadife.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Error banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: cadife.primary.withValues(alpha: 0.08),
      child: Row(
        children: [
          Icon(LucideIcons.circleAlert, size: 16, color: cadife.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Não foi possível carregar o itinerário.',
              style: TextStyle(fontSize: 13, color: cadife.primary),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              'Tentar novamente',
              style: TextStyle(
                fontSize: 13,
                color: cadife.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
