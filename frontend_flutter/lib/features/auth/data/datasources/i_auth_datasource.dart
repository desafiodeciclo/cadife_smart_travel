import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';

abstract class IAuthDatasource {
  Future<Map<String, dynamic>> login(String email, String password, {UserRole? profileHint});
  Future<Map<String, dynamic>> register(String name, String email, String password);
  Future<void> logout();
  Future<Map<String, dynamic>?> getUserProfile();
  Future<Map<String, dynamic>> refreshToken(String refreshToken);
  Future<void> saveFcmToken(String token);
  Future<void> forgotPassword(String email);
  Future<void> changePassword(String currentPassword, String newPassword);
  Future<void> resetPassword(String token, String newPassword);
  Future<void> logoutAllDevices();
}
