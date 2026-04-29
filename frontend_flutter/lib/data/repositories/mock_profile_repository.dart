import 'package:cadife_smart_travel/core/ports/profile_port.dart';
import 'package:cadife_smart_travel/shared/models/user_model.dart';

/// Mock de ProfilePort para desenvolvimento local.
///
/// Não faz chamadas HTTP — retorna um usuário cliente mockado
/// com preferências de viagem preenchidas.
class MockProfileRepository implements ProfilePort {
  UserModel? _user;

  @override
  Future<UserModel> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 400));
    _user ??= UserModel(
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
  Future<UserModel> updateProfile({
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
