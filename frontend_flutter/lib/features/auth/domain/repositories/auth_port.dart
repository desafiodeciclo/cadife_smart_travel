import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';

abstract class AuthPort {
  Future<AuthUser> login(String email, String password, {UserRole? profileHint});
  Future<AuthUser> register(String name, String email, String password);
  Future<void> logout();
  Future<TokenModel> refreshToken(String refreshToken);
  Future<AuthUser?> getCurrentUser();
  Future<bool> isLoggedIn();
  Future<void> saveFcmToken(String token);
  Future<void> forgotPassword(String email);
}



