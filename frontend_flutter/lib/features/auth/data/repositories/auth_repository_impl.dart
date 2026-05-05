import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/core/security/jwt_utils.dart';
import 'package:cadife_smart_travel/core/security/secure_config.dart';
import 'package:cadife_smart_travel/features/auth/data/datasources/i_auth_datasource.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:fpdart/fpdart.dart';

class AuthRepositoryImpl implements IAuthRepository {
  AuthRepositoryImpl({
    required IAuthDatasource remoteDatasource,
    required SecureConfig secureConfig,
  })  : _remoteDatasource = remoteDatasource,
        _secureConfig = secureConfig;

  final IAuthDatasource _remoteDatasource;
  final SecureConfig _secureConfig;

  @override
  Future<Either<Failure, AuthUser>> login(String email, String password, {UserRole? profileHint}) async {
    try {
      final data = await _remoteDatasource.login(email, password, profileHint: profileHint);
      
      final tokenData = data['token'] as Map<String, dynamic>;
      await _secureConfig.saveTokens(
        accessToken: tokenData['access_token'] as String,
        refreshToken: tokenData['refresh_token'] as String,
      );
      
      return Right(AuthUser.fromJson(data['user'] as Map<String, dynamic>));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> register(String name, String email, String password) async {
    try {
      final data = await _remoteDatasource.register(name, email, password);
      return Right(AuthUser.fromJson(data));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      try {
        await _remoteDatasource.logout();
      } catch (_) {
        // Ignore remote logout errors
      }
      await _secureConfig.clearTokens();
      return const Right(null);
    } catch (e) {
      return Left(GenericFailure(e.toString()));
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
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser?>> getCurrentUser() async {
    try {
      final data = await _remoteDatasource.getCurrentUser();
      if (data != null) {
        return Right(AuthUser.fromJson(data));
      }
      final user = await _getUserFromStoredToken();
      return Right(user);
    } catch (_) {
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
      name: payload['name'] as String? ?? payload['email'] as String? ?? 'Usuário',
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
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveFcmToken(String token) async {
    try {
      await _remoteDatasource.saveFcmToken(token);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> forgotPassword(String email) async {
    try {
      await _remoteDatasource.forgotPassword(email);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
