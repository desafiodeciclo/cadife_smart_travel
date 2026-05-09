import 'dart:async';

import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:cadife_smart_travel/core/network/network_info.dart';
import 'package:cadife_smart_travel/features/client/itinerary/data/services/itinerary_service.dart';
import 'package:cadife_smart_travel/features/client/itinerary/domain/entities/itinerary_item.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CalendarViewMode { mensal, diaria }

class ItineraryState extends Equatable {
  const ItineraryState({
    this.items = const [],
    this.selectedDate,
    this.viewMode = CalendarViewMode.mensal,
    this.isLoading = false,
    this.isSyncing = false,
    this.isOffline = false,
    this.error,
    this.lastSyncedAt,
  });

  final List<ItineraryItem> items;
  final DateTime? selectedDate;
  final CalendarViewMode viewMode;
  final bool isLoading;
  final bool isSyncing;
  final bool isOffline;
  final String? error;
  final DateTime? lastSyncedAt;

  ItineraryState copyWith({
    List<ItineraryItem>? items,
    DateTime? selectedDate,
    CalendarViewMode? viewMode,
    bool? isLoading,
    bool? isSyncing,
    bool? isOffline,
    String? error,
    DateTime? lastSyncedAt,
    bool clearError = false,
  }) {
    return ItineraryState(
      items: items ?? this.items,
      selectedDate: selectedDate ?? this.selectedDate,
      viewMode: viewMode ?? this.viewMode,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      isOffline: isOffline ?? this.isOffline,
      error: clearError ? null : (error ?? this.error),
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
 
  @override
  List<Object?> get props => [
        items,
        selectedDate,
        viewMode,
        isLoading,
        isSyncing,
        isOffline,
        error,
        lastSyncedAt,
      ];

  List<ItineraryItem> itemsForDay(DateTime day) {
    return items
        .where(
          (item) =>
              item.dataHora.year == day.year &&
              item.dataHora.month == day.month &&
              item.dataHora.day == day.day,
        )
        .toList()
      ..sort((a, b) => a.dataHora.compareTo(b.dataHora));
  }

  Map<DateTime, List<ItineraryItem>> get itemsByDay {
    final map = <DateTime, List<ItineraryItem>>{};
    for (final item in items) {
      final key = DateTime(
        item.dataHora.year,
        item.dataHora.month,
        item.dataHora.day,
      );
      (map[key] ??= []).add(item);
    }
    return map;
  }
}

class ItineraryNotifier extends FamilyNotifier<ItineraryState, String> {
  Timer? _pollingTimer;

  @override
  ItineraryState build(String arg) {
    ref.onDispose(() => _pollingTimer?.cancel());
    Future.microtask(() => loadItinerary(arg));
    _startPolling(arg);
    return ItineraryState(selectedDate: DateTime.now());
  }

  void _startPolling(String leadId) {
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _syncIfOnline(leadId),
    );
  }

  Future<void> _syncIfOnline(String leadId) async {
    final isOnline = await sl<NetworkInfo>().isConnected;
    if (!isOnline) return;
    await syncItinerary(leadId);
  }

  Future<void> loadItinerary(String leadId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final isOnline = await sl<NetworkInfo>().isConnected;
      final service = sl<ItineraryService>();
      final items = await service.fetchItinerary(leadId);
      if (isOnline) {
        await service.syncPendingNotes(leadId);
      }
      state = state.copyWith(
        items: items,
        isLoading: false,
        isOffline: !isOnline,
        lastSyncedAt: service.lastSyncedAt(leadId),
      );
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> syncItinerary(String leadId) async {
    if (state.isSyncing) return;
    state = state.copyWith(isSyncing: true);
    try {
      final service = sl<ItineraryService>();
      final items = await service.fetchItinerary(leadId);
      state = state.copyWith(
        items: items,
        isSyncing: false,
        isOffline: false,
        lastSyncedAt: service.lastSyncedAt(leadId),
      );
    } on Exception catch (_) {
      state = state.copyWith(isSyncing: false);
    }
  }

  void selectDate(DateTime date, {bool switchToDailyView = false}) {
    state = state.copyWith(
      selectedDate: date,
      viewMode:
          switchToDailyView ? CalendarViewMode.diaria : state.viewMode,
    );
  }

  void setViewMode(CalendarViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  Future<void> saveNote(String leadId, String date, String nota) async {
    await sl<ItineraryService>().saveNote(leadId, date, nota);
  }

  String? getNote(String leadId, String date) =>
      sl<ItineraryService>().getNote(leadId, date);
}

final itineraryProvider = NotifierProvider.family<ItineraryNotifier,
    ItineraryState, String>(
  ItineraryNotifier.new,
);
