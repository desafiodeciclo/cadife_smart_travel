import 'package:fpdart/fpdart.dart';
import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';

abstract class IAuthRepository {
  Future<Either<Failure, AuthUser>> login(String email, String password, {UserRole? profileHint});
  Future<Either<Failure, AuthUser>> register(String name, String email, String password);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, AuthUser?>> getCurrentUser();
  Future<Either<Failure, bool>> isLoggedIn();
  Future<Either<Failure, void>> forgotPassword(String email);
  Future<Either<Failure, TokenModel>> refreshToken(String refreshToken);
  Future<Either<Failure, void>> saveFcmToken(String token);
}
