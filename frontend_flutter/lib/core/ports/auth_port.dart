import 'package:cadife_smart_travel/shared/models/user_model.dart';

abstract class AuthPort {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String name, String email, String password);
  Future<void> logout();
  Future<TokenModel> refreshToken(String refreshToken);
  Future<UserModel?> getCurrentUser();
  Future<bool> isLoggedIn();
  Future<void> saveFcmToken(String token);
}
