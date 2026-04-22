import 'dart:convert';

import 'package:cadife_smart_travel/core/network/network_info.dart';
import 'package:cadife_smart_travel/core/utils/result.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum SyncQueueStatus {
  pending,
  syncing,
  failed,
}

class SyncQueueEntry {
  const SyncQueueEntry({
    required this.id,
    required this.method,
    required this.path,
    required this.body,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
  });

  final String id;
  final String method;
  final String path;
  final String body;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;

  Map<String, dynamic> toMap() => {
        'id': id,
        'method': method,
        'path': path,
        'body': body,
        'created_at': createdAt.toIso8601String(),
        'retry_count': retryCount,
        'last_error': lastError,
      };

  factory SyncQueueEntry.fromMap(Map<String, dynamic> map) => SyncQueueEntry(
        id: map['id'] as String,
        method: map['method'] as String,
        path: map['path'] as String,
        body: map['body'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        retryCount: map['retry_count'] as int? ?? 0,
        lastError: map['last_error'] as String?,
      );
}

class OfflineSyncQueue {
  OfflineSyncQueue({required NetworkInfo networkInfo, HiveInterface? hive})
      : _networkInfo = networkInfo,
        _hive = hive ?? Hive;

  final NetworkInfo _networkInfo;
  final HiveInterface _hive;
  late Box<dynamic> _syncBox;
  bool _isInitialized = false;
  bool _isSyncing = false;

  static const _maxRetries = 3;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _syncBox = await _hive.openBox<dynamic>('sync_queue');
    _isInitialized = true;

    _networkInfo.onConnectivityChanged.listen((isOnline) {
      if (isOnline) flush();
    });
  }

  Future<Result<void>> enqueue({
    required String method,
    required String path,
    required Map<String, dynamic> body,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final isOnline = await _networkInfo.isConnected;
    if (isOnline) {
      return const Success(null);
    }

    final entry = SyncQueueEntry(
      id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
      method: method,
      path: path,
      body: jsonEncode(body),
      createdAt: DateTime.now(),
    );

    await _syncBox.put(entry.id, entry.toMap());
    return const Success(null);
  }

  Future<void> flush() async {
    if (_isSyncing || !_isInitialized) return;
    _isSyncing = true;

    try {
      final isOnline = await _networkInfo.isConnected;
      if (!isOnline) return;

      final entries = _syncBox.values
          .map((e) => SyncQueueEntry.fromMap(e as Map<String, dynamic>))
          .where((e) => e.retryCount < _maxRetries)
          .toList();

      for (final entry in entries) {
        try {
          await _syncBox.delete(entry.id);
        } catch (e) {
          final updated = SyncQueueEntry(
            id: entry.id,
            method: entry.method,
            path: entry.path,
            body: entry.body,
            createdAt: entry.createdAt,
            retryCount: entry.retryCount + 1,
            lastError: e.toString(),
          );
          await _syncBox.put(entry.id, updated.toMap());
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  int get pendingCount {
    if (!_isInitialized) return 0;
    return _syncBox.length;
  }

  bool get hasPending => pendingCount > 0;

  Future<void> clear() async {
    if (!_isInitialized) return;
    await _syncBox.clear();
  }

  Future<void> dispose() async {
    if (_isInitialized) {
      await _syncBox.close();
    }
  }
}