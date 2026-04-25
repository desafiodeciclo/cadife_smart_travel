import 'package:cadife_smart_travel/core/network/network_info.dart';
import 'package:cadife_smart_travel/core/offline/offline_manager.dart';
import 'package:cadife_smart_travel/core/offline/offline_sync_queue.dart';
import 'package:cadife_smart_travel/core/utils/result.dart';

typedef OnlineFirstCallback<T> = Future<T> Function();

class OfflineFirst {
  OfflineFirst({
    required OfflineManager offlineManager,
    required NetworkInfo networkInfo,
    required OfflineSyncQueue syncQueue,
  }) : _offlineManager = offlineManager,
       _networkInfo = networkInfo,
       _syncQueue = syncQueue;

  final OfflineManager _offlineManager;
  final NetworkInfo _networkInfo;
  final OfflineSyncQueue _syncQueue;

  Future<Result<T>> onlineFirst<T>({
    required String cacheKey,
    required OnlineFirstCallback<T> remoteCall,
    required T Function(dynamic cached) fromCache,
    int? expiryMinutes,
    bool returnExpiredOffline = true,
  }) async {
    final isOnline = await _networkInfo.isConnected;

    if (isOnline) {
      try {
        final data = await remoteCall();
        return Success(data);
      } catch (e) {
        if (returnExpiredOffline) {
          return _fromCacheOrFailure(cacheKey, fromCache);
        }
        return Failure(e);
      }
    }

    return _fromCacheOrFailure(cacheKey, fromCache);
  }

  Future<Result<T>> cacheFirst<T>({
    required String cacheKey,
    required OnlineFirstCallback<T> remoteCall,
    required T Function(dynamic cached) fromCache,
    int? expiryMinutes,
  }) async {
    final cached = _offlineManager.getFromCache(
      cacheKey,
      expiryMinutes: expiryMinutes,
    );
    if (cached != null) {
      try {
        return Success(fromCache(cached));
      } catch (_) {
        // Cache corrupted, try fresh
      }
    }

    final isOnline = await _networkInfo.isConnected;
    if (!isOnline) {
      final offlineData = _offlineManager.getFromCacheOffline(cacheKey);
      if (offlineData != null) {
        try {
          return Success(fromCache(offlineData));
        } catch (_) {}
      }
      return Failure(Exception('No cached data and device is offline'));
    }

    try {
      final data = await remoteCall();
      return Success(data);
    } catch (e) {
      return Failure(e);
    }
  }

  Future<Result<T>> writeThrough<T>({
    required String cacheKey,
    required OnlineFirstCallback<T> remoteCall,
    required T Function(dynamic cached) fromCache,
    String? syncMethod,
    String? syncPath,
    Map<String, dynamic>? syncBody,
  }) async {
    final isOnline = await _networkInfo.isConnected;

    if (isOnline) {
      try {
        final data = await remoteCall();
        return Success(data);
      } catch (e) {
        return Failure(e);
      }
    }

    if (syncMethod != null && syncPath != null && syncBody != null) {
      await _syncQueue.enqueue(
        method: syncMethod,
        path: syncPath,
        body: syncBody,
      );
    }

    return Failure(Exception('Device offline — operation queued for sync'));
  }

  Result<T> _fromCacheOrFailure<T>(
    String cacheKey,
    T Function(dynamic) fromCache,
  ) {
    final cached = _offlineManager.getFromCacheOffline(cacheKey);
    if (cached != null) {
      try {
        return Success(fromCache(cached));
      } catch (_) {}
    }

    return Failure(Exception('No cached data available offline'));
  }
}
