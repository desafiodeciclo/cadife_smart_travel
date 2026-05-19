import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/core/security/jwt_utils.dart';
import 'package:cadife_smart_travel/core/security/secure_config.dart';
import 'package:cadife_smart_travel/features/auth/data/datasources/i_auth_datasource.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

class AuthRepositoryImpl implements IAuthRepository {
  AuthRepositoryImpl({
    required IAuthDatasource remoteDatasource,
    required SecureConfig secureConfig,
  }) : _remoteDatasource = remoteDatasource,
       _secureConfig = secureConfig;

  final IAuthDatasource _remoteDatasource;
  final SecureConfig _secureConfig;

  @override
  Future<Either<Failure, AuthUser>> login(
    String email,
    String password, {
    UserRole? profileHint,
  }) async {
    try {
      final data = await _remoteDatasource.login(
        email,
        password,
        profileHint: profileHint,
      );
      return await _handleAuthResponse(data);
    } on Exception catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  Future<Either<Failure, AuthUser>> _handleAuthResponse(
    Map<String, dynamic> data,
  ) async {
    debugPrint('AUTH_REPO: Raw data received: $data');
    // Backend sends tokens at top level: {access_token, refresh_token}
    // But might also be wrapped: {token: {access_token, refresh_token}}
    final Map<String, dynamic> tokenData = (data['token'] is Map) 
        ? data['token'] as Map<String, dynamic> 
        : data;

    final accessToken = tokenData['access_token']?.toString();
    final refreshToken = tokenData['refresh_token']?.toString();
    
    if (accessToken == null || refreshToken == null) {
      return const Left(ServerFailure('Token ausente na resposta do servidor.'));
    }

    await _secureConfig.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    debugPrint('DEBUG: Tokens saved successfully. Fetching profile...');

    // Small delay to ensure SecureStorage is ready
    await Future.delayed(const Duration(milliseconds: 500));

    // Try to get user from response (might be in 'user' key or at top level if it's a UserResponse)
    final userData = (data['user'] is Map) ? data['user'] as Map<String, dynamic> : data;
    
    // Check if we actually have user data (backend UserResponse has 'email' or 'id')
    if (userData.containsKey('email') || userData.containsKey('id')) {
      return Right(AuthUser.fromJson(userData));
    }

    // Fallback: mandatory fetch for /me since register doesn't return user data
    try {
      final currentUserData = await _remoteDatasource.getUserProfile();
      if (currentUserData != null) {
        return Right(AuthUser.fromJson(currentUserData));
      }
    } catch (e) {
      return Left(ServerFailure('Erro ao recuperar perfil: $e'));
    }

    return const Left(ServerFailure('Dados do usuário não encontrados.'));
  }

  @override
  Future<Either<Failure, AuthUser>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final data = await _remoteDatasource.register(name, email, password);
      return _handleAuthResponse(data);
    } on Exception catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      try {
        await _remoteDatasource.logout();
      } on Object catch (_) {
        // Ignore remote logout errors
      }
      await _secureConfig.clearTokens();
      return const Right(null);
    } on Exception catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, TokenModel>> refreshToken(String refreshToken) async {
    try {
      final data = await _remoteDatasource.refreshToken(refreshToken);

      await _secureConfig.saveTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
      );

      return Right(TokenModel.fromJson(data));
    } on Exception catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, AuthUser?>> getUserProfile() async {
    try {
      final data = await _remoteDatasource.getUserProfile();
      if (data != null) {
        return Right(AuthUser.fromJson(data));
      }
      final user = await _getUserFromStoredToken();
      return Right(user);
    } on Object catch (_) {
      final user = await _getUserFromStoredToken();
      return Right(user);
    }
  }

  Future<AuthUser?> _getUserFromStoredToken() async {
    final token = await _secureConfig.getAccessToken();
    if (token == null) return null;

    final payload = JwtUtils.decodePayload(token);
    if (payload == null) return null;

    return AuthUser(
      id: payload['sub'] as String? ?? '',
      name:
          payload['name'] as String? ??
          payload['email'] as String? ??
          'Usuário',
      email: payload['email'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == (payload['role'] as String?),
        orElse: () => UserRole.cliente,
      ),
    );
  }

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    try {
      final token = await _secureConfig.getAccessToken();
      return Right(token != null);
    } on Exception catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> saveFcmToken(String token) async {
    try {
      await _remoteDatasource.saveFcmToken(token);
      return const Right(null);
    } on Exception catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> forgotPassword(String email) async {
    try {
      await _remoteDatasource.forgotPassword(email);
      return const Right(null);
    } on Exception catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      await _remoteDatasource.changePassword(currentPassword, newPassword);
      return const Right(null);
    } on Exception catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(
    String token,
    String newPassword,
  ) async {
    try {
      await _remoteDatasource.resetPassword(token, newPassword);
      return const Right(null);
    } on Exception catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> logoutAllDevices() async {
    try {
      await _remoteDatasource.logoutAllDevices();
      return const Right(null);
    } on Exception catch (e) {
      return Left(Failure.fromException(e));
    }
  }
}
