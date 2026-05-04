import 'package:cadife_smart_travel/core/constants/api_constants.dart';
import 'package:cadife_smart_travel/core/offline/offline_manager.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/client/profile/domain/repositories/profile_port.dart';
import 'package:dio/dio.dart';

class ProfileRepositoryImpl implements ProfilePort {
  ProfileRepositoryImpl({required Dio dio, required OfflineManager offlineManager})
    : _dio = dio,
      _offlineManager = offlineManager;

  final Dio _dio;
  final OfflineManager _offlineManager;

  static const _cacheKey = 'profile:me';

  @override
  Future<AuthUser> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiConstants.me);
      final user = AuthUser.fromJson(response.data as Map<String, dynamic>);

      await _offlineManager.saveToCache(_cacheKey, response.data);
      return user;
    } on DioException {
      final cached = _offlineManager.getFromCacheOffline(_cacheKey);
      if (cached != null) {
        return AuthUser.fromJson(cached as Map<String, dynamic>);
      }
      rethrow;
    }
  }

  @override
  Future<AuthUser> updateProfile({
    String? name,
    List<String>? tipoViagem,
    List<String>? preferencias,
    bool? temPassaporte,
  }) async {
    final response = await _dio.patch(
      ApiConstants.me,
      data: {
        'nome': name,
        'tipo_viagem': tipoViagem,
        'preferencias': preferencias,
        'tem_passaporte': temPassaporte,
      }..removeWhere((_, v) => v == null),
    );
    final user = AuthUser.fromJson(response.data as Map<String, dynamic>);

    await _offlineManager.saveToCache(_cacheKey, response.data);
    return user;
  }
}




