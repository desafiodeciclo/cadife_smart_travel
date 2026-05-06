import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/core/network/network_info.dart';
import 'package:cadife_smart_travel/core/offline/offline_manager.dart';
import 'package:cadife_smart_travel/core/offline/offline_sync_queue.dart';
import 'package:fpdart/fpdart.dart';

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

  Future<Either<Failure, T>> onlineFirst<T>({
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
        return Right(data);
      } on Exception catch (e) {
        if (returnExpiredOffline) {
          return _fromCacheOrFailure(cacheKey, fromCache);
        }
        return Left(Failure.fromException(e));
      }
    }

    return _fromCacheOrFailure(cacheKey, fromCache);
  }

  Future<Either<Failure, T>> cacheFirst<T>({
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
        return Right(fromCache(cached));
      } on Object catch (_) {
        // Cache corrupted, try fresh
      }
    }

    final isOnline = await _networkInfo.isConnected;
    if (!isOnline) {
      final offlineData = _offlineManager.getFromCacheOffline(cacheKey);
      if (offlineData != null) {
        try {
          return Right(fromCache(offlineData));
        } on Object catch (_) {}
      }
      return const Left(CacheFailure('No cached data and device is offline'));
    }

    try {
      final data = await remoteCall();
      return Right(data);
    } on Exception catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  Future<Either<Failure, T>> writeThrough<T>({
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
        return Right(data);
      } on Exception catch (e) {
        return Left(Failure.fromException(e));
      }
    }

    if (syncMethod != null && syncPath != null && syncBody != null) {
      await _syncQueue.enqueue(
        method: syncMethod,
        path: syncPath,
        body: syncBody,
      );
    }

    return const Left(NetworkFailure('Device offline — operation queued for sync'));
  }

  Either<Failure, T> _fromCacheOrFailure<T>(
    String cacheKey,
    T Function(dynamic) fromCache,
  ) {
    final cached = _offlineManager.getFromCacheOffline(cacheKey);
    if (cached != null) {
      try {
        return Right(fromCache(cached));
      } on Object catch (_) {}
    }

    return const Left(CacheFailure('No cached data available offline'));
  }
}
