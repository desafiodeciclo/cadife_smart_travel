import 'dart:convert';
import 'dart:developer';

import 'package:cadife_smart_travel/core/constants/api_constants.dart';
import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:cadife_smart_travel/features/client/itinerary/domain/entities/itinerary_item.dart';
import 'package:dio/dio.dart';
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
      log('fetchItinerary error', name: 'ItineraryService', error: e);
      return _loadFromCache(leadId);
    }
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
      log('saveNote offline – will retry', name: 'ItineraryService', error: e);
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
        log('syncPendingNotes failed for $date', name: 'ItineraryService', error: e);
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
