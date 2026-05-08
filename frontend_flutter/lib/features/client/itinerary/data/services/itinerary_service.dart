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
    // Para fins de demonstração/mock, se o ID começar com 'trip-h' ou for o mock padrão, retornamos dados mockados
    if (leadId.startsWith('trip-h') || leadId == 'mock-lead-123') {
      await Future.delayed(const Duration(milliseconds: 800));
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
    final now = DateTime.now();
    return [
      ItineraryItem(
        id: 'mock-itin-1',
        leadId: leadId,
        tipo: ItineraryItemType.voo,
        titulo: 'Voo para o Destino',
        descricao: 'Voo operado pela LATAM. Terminal 3.',
        local: 'Aeroporto Internacional',
        dataHora: DateTime(now.year, now.month, now.day, 10, 30),
      ),
      ItineraryItem(
        id: 'mock-itin-2',
        leadId: leadId,
        tipo: ItineraryItemType.hotelCheckin,
        titulo: 'Check-in no Hotel',
        descricao: 'Reserva confirmada. Apresentar voucher.',
        local: 'Hotel Grand Hyatt',
        dataHora: DateTime(now.year, now.month, now.day, 15, 00),
      ),
      ItineraryItem(
        id: 'mock-itin-3',
        leadId: leadId,
        tipo: ItineraryItemType.refeicao,
        titulo: 'Jantar de Boas-vindas',
        descricao: 'Reserva em nome de Cadife.',
        local: 'Restaurante Le Gourmet',
        dataHora: DateTime(now.year, now.month, now.day, 20, 00),
      ),
      ItineraryItem(
        id: 'mock-itin-4',
        leadId: leadId,
        tipo: ItineraryItemType.passeio,
        titulo: 'Tour pela Cidade',
        descricao: 'Guia privativo em português.',
        local: 'Ponto de encontro no Lobby',
        dataHora: DateTime(now.year, now.month, now.day + 1, 09, 00),
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
