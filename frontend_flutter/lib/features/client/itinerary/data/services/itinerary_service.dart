import 'dart:convert';

import 'package:cadife_smart_travel/core/constants/api_constants.dart';
import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:cadife_smart_travel/features/client/itinerary/domain/entities/itinerary_item.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ItineraryService {
  ItineraryService({Dio? dio, SharedPreferences? prefs})
      : _dio = dio ?? sl<Dio>(),
        _prefs = prefs ?? sl<SharedPreferences>();

  final Dio _dio;
  final SharedPreferences _prefs;

  static String _dataKey(String leadId) => 'itin_data_$leadId';
  static String _syncKey(String leadId) => 'itin_sync_$leadId';
  static String _noteKey(String leadId, String date) =>
      'day_note_${leadId}_$date';
  static String _pendingKey(String leadId) => 'day_note_${leadId}_pending';

  Future<List<ItineraryItem>> fetchItinerary(String leadId) async {
    if (leadId.startsWith('trip-') || leadId == 'mock-lead-123') {
      await Future.delayed(const Duration(milliseconds: 600));
      return _getMockItinerary(leadId);
    }

    try {
      final response = await _dio.get(ApiConstants.leadItinerary(leadId));
      final data = response.data as Map<String, dynamic>;
      final items = (data['itinerary'] as List<dynamic>)
          .map(
            (e) => ItineraryItem.fromJson(e as Map<String, dynamic>, leadId),
          )
          .toList();
      await _saveToCache(leadId, items);
      return items;
    } on DioException catch (e) {
      debugPrint('ItineraryService.fetchItinerary error: $e');
      return _loadFromCache(leadId);
    }
  }

  List<ItineraryItem> _getMockItinerary(String leadId) {
    // Usa datas relativas ao mock de viagem Paris (jun/2026) para não depender de DateTime.now()
    final d1 = DateTime(2026, 6, 15);
    final d2 = DateTime(2026, 6, 16);
    final d3 = DateTime(2026, 6, 17);
    final d4 = DateTime(2026, 6, 18);
    final d5 = DateTime(2026, 6, 22);
    return [
      ItineraryItem(
        id: 'mock-itin-1',
        leadId: leadId,
        tipo: ItineraryItemType.voo,
        titulo: 'Voo GRU → CDG',
        descricao: 'LATAM LA705 — Terminal 3. Check-in às 08h.',
        local: 'Aeroporto de Guarulhos (GRU)',
        dataHora: DateTime(d1.year, d1.month, d1.day, 10, 00),
        dataHoraFim: DateTime(d1.year, d1.month, d1.day, 22, 30),
        notas: 'Franquia de bagagem: 2 × 23 kg',
      ),
      ItineraryItem(
        id: 'mock-itin-2',
        leadId: leadId,
        tipo: ItineraryItemType.hotelCheckin,
        titulo: 'Check-in — Hôtel Le Marais',
        descricao: 'Reserva confirmada. Apresentar voucher impresso.',
        local: 'Rue de Bretagne, 42, Paris',
        dataHora: DateTime(d1.year, d1.month, d1.day, 23, 30),
        dataHoraFim: DateTime(d5.year, d5.month, d5.day, 11, 00),
      ),
      ItineraryItem(
        id: 'mock-itin-3',
        leadId: leadId,
        tipo: ItineraryItemType.passeio,
        titulo: 'Tour pela Torre Eiffel',
        descricao: 'Guia privativo em português. Ingresso incluso.',
        local: 'Champ de Mars, Paris',
        dataHora: DateTime(d2.year, d2.month, d2.day, 9, 00),
        dataHoraFim: DateTime(d2.year, d2.month, d2.day, 12, 00),
      ),
      ItineraryItem(
        id: 'mock-itin-4',
        leadId: leadId,
        tipo: ItineraryItemType.refeicao,
        titulo: 'Almoço — Café de Flore',
        descricao: 'Reserva em nome de Cadife Tour.',
        local: '172 Boulevard Saint-Germain, Paris',
        dataHora: DateTime(d2.year, d2.month, d2.day, 13, 00),
        dataHoraFim: DateTime(d2.year, d2.month, d2.day, 14, 30),
      ),
      ItineraryItem(
        id: 'mock-itin-5',
        leadId: leadId,
        tipo: ItineraryItemType.passeio,
        titulo: 'Museu do Louvre',
        descricao: 'Visita autoguiada. Audioguia em português disponível.',
        local: 'Rue de Rivoli, Paris',
        dataHora: DateTime(d3.year, d3.month, d3.day, 10, 00),
        dataHoraFim: DateTime(d3.year, d3.month, d3.day, 13, 00),
      ),
      ItineraryItem(
        id: 'mock-itin-6',
        leadId: leadId,
        tipo: ItineraryItemType.passeio,
        titulo: 'Versalhes — Palácio e Jardins',
        descricao: 'Transfer incluso. Ingresso e audioguia inclusos.',
        local: 'Place d\'Armes, Versailles',
        dataHora: DateTime(d4.year, d4.month, d4.day, 9, 30),
        dataHoraFim: DateTime(d4.year, d4.month, d4.day, 17, 00),
      ),
      ItineraryItem(
        id: 'mock-itin-7',
        leadId: leadId,
        tipo: ItineraryItemType.hotelCheckout,
        titulo: 'Checkout — Hôtel Le Marais',
        descricao: 'Entregar chaves até 11h. Bagagem pode ser guardada.',
        local: 'Rue de Bretagne, 42, Paris',
        dataHora: DateTime(d5.year, d5.month, d5.day, 11, 00),
      ),
      ItineraryItem(
        id: 'mock-itin-8',
        leadId: leadId,
        tipo: ItineraryItemType.voo,
        titulo: 'Voo CDG → GRU',
        descricao: 'LATAM LA706 — Embarque às 15h30.',
        local: 'Aeroporto Charles de Gaulle (CDG)',
        dataHora: DateTime(d5.year, d5.month, d5.day, 14, 00),
        dataHoraFim: DateTime(d5.year, d5.month, d5.day + 1, 5, 00),
      ),
    ];
  }

  List<ItineraryItem> _loadFromCache(String leadId) {
    final json = _prefs.getString(_dataKey(leadId));
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map(
            (e) => ItineraryItem.fromJson(e as Map<String, dynamic>, leadId),
          )
          .toList();
    } on Exception catch (_) {
      return [];
    }
  }

  Future<void> _saveToCache(
    String leadId,
    List<ItineraryItem> items,
  ) async {
    await _prefs.setString(
      _dataKey(leadId),
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
    await _prefs.setString(
      _syncKey(leadId),
      DateTime.now().toIso8601String(),
    );
  }

  bool isCacheStale(String leadId, {int maxAgeMinutes = 60}) {
    final raw = _prefs.getString(_syncKey(leadId));
    if (raw == null) return true;
    try {
      return DateTime.now()
              .difference(DateTime.parse(raw))
              .inMinutes >
          maxAgeMinutes;
    } on Exception catch (_) {
      return true;
    }
  }

  DateTime? lastSyncedAt(String leadId) {
    final raw = _prefs.getString(_syncKey(leadId));
    if (raw == null) return null;
    try {
      return DateTime.parse(raw);
    } on Exception catch (_) {
      return null;
    }
  }

  Future<void> saveNote(String leadId, String date, String nota) async {
    await _prefs.setString(_noteKey(leadId, date), nota);
    await _addPendingNote(leadId, date);
    try {
      await _dio.put(
        ApiConstants.leadNote(leadId, date),
        data: {'nota': nota},
      );
      await _removePendingNote(leadId, date);
    } on DioException catch (e) {
      debugPrint('ItineraryService.saveNote offline – will retry: $e');
    }
  }

  String? getNote(String leadId, String date) =>
      _prefs.getString(_noteKey(leadId, date));

  Future<void> syncPendingNotes(String leadId) async {
    final pending = _getPendingNotes(leadId);
    for (final date in List<String>.from(pending)) {
      final nota = _prefs.getString(_noteKey(leadId, date));
      if (nota == null) continue;
      try {
        await _dio.put(
          ApiConstants.leadNote(leadId, date),
          data: {'nota': nota},
        );
        await _removePendingNote(leadId, date);
      } on DioException catch (e) {
        debugPrint('syncPendingNotes failed for $date: $e');
      }
    }
  }

  List<String> _getPendingNotes(String leadId) {
    final raw = _prefs.getString(_pendingKey(leadId));
    if (raw == null) return [];
    try {
      return List<String>.from(jsonDecode(raw) as List);
    } on Exception catch (_) {
      return [];
    }
  }

  Future<void> _addPendingNote(String leadId, String date) async {
    final pending = _getPendingNotes(leadId);
    if (!pending.contains(date)) {
      pending.add(date);
      await _prefs.setString(_pendingKey(leadId), jsonEncode(pending));
    }
  }

  Future<void> _removePendingNote(String leadId, String date) async {
    final pending = _getPendingNotes(leadId)..remove(date);
    await _prefs.setString(_pendingKey(leadId), jsonEncode(pending));
  }
}
