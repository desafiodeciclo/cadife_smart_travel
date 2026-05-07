import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_event.freezed.dart';

@freezed
class AuthEvent with _$AuthEvent {
  const factory AuthEvent.authCheckRequested() = AuthCheckRequested;
  const factory AuthEvent.loginRequested({
    required String email,
    required String password,
    UserRole? profileHint,
  }) = AuthLoginRequested;
  const factory AuthEvent.logoutRequested() = AuthLogoutRequested;
  const factory AuthEvent.forgotPasswordRequested({required String email}) = AuthForgotPasswordRequested;
}
