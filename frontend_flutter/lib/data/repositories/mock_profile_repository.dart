import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/client/profile/domain/repositories/profile_port.dart';

/// Mock de ProfilePort para desenvolvimento local.
///
/// NÃƒÂ£o faz chamadas HTTP Ã¢â‚¬â€ retorna um usuÃƒÂ¡rio cliente mockado
/// com preferÃƒÂªncias de viagem preenchidas.
class MockProfileRepository implements ProfilePort {
  AuthUser? _user;

  @override
  Future<AuthUser> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 400));
    _user ??= AuthUser(
      id: 'mock-client-001',
      name: 'Maria Fernanda Costa',
      email: 'maria.costa@email.com',
      role: UserRole.cliente,
      phone: '+55 11 98765-4321',
      avatarUrl: null,
      createdAt: DateTime(2024, 3, 12),
      tipoViagem: ['turismo', 'lazer', 'aventura'],
      preferencias: ['praia', 'calor', 'luxo'],
      temPassaporte: true,
    );
    return _user!;
  }

  @override
  Future<AuthUser> updateProfile({
    String? name,
    List<String>? tipoViagem,
    List<String>? preferencias,
    bool? temPassaporte,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _user = _user!.copyWith(
      name: name,
      tipoViagem: tipoViagem,
      preferencias: preferencias,
      temPassaporte: temPassaporte,
    );
    return _user!;
  }
}




