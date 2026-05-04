import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/client/profile/domain/repositories/i_profile_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Mock de IProfileRepository para desenvolvimento local.
///
/// Não faz chamadas HTTP — retorna um usuário cliente mockado
/// com preferências de viagem preenchidas.
class MockProfileRepository implements IProfileRepository {
  AuthUser? _user;

  @override
  Future<Either<Failure, AuthUser>> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 400));
    _user ??= AuthUser(
      id: 'mock-client-001',
      name: 'Maria Fernanda Costa',
      email: 'maria.costa@email.com',
      role: UserRole.cliente,
      phone: '+55 11 98765-4321',
      avatarUrl: null,
      createdAt: DateTime(2024, 3, 12),
      tipoViagem: const ['turismo', 'lazer', 'aventura'],
      preferencias: const ['praia', 'calor', 'luxo'],
      temPassaporte: true,
    );
    return Right(_user!);
  }

  @override
  Future<Either<Failure, AuthUser>> updateProfile({
    String? name,
    List<String>? tipoViagem,
    List<String>? preferencias,
    bool? temPassaporte,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (_user == null) {
      await getCurrentUser();
    }
    _user = _user!.copyWith(
      name: name,
      tipoViagem: tipoViagem,
      preferencias: preferencias,
      temPassaporte: temPassaporte,
    );
    return Right(_user!);
  }
}
