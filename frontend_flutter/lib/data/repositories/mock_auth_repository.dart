import 'package:cadife_smart_travel/core/ports/auth_port.dart';
import 'package:cadife_smart_travel/core/security/secure_config.dart';
import 'package:cadife_smart_travel/shared/models/user_model.dart';

/// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
/// AVISO: ESTE REPOSITÓRIO É APENAS PARA DESENVOLVIMENTO (MOCK).
/// DEVE SER REMOVIDO OU SUBSTITUÍDO PELO AuthRepositoryImpl EM PRODUÇÃO.
/// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
class MockAuthRepository implements AuthPort {
  MockAuthRepository({required SecureConfig secureConfig}) : _secureConfig = secureConfig;

  final SecureConfig _secureConfig;
  UserModel? _currentUser;

  @override
  Future<UserModel> login(String email, String password) async {
    // Simula delay de rede
    await Future.delayed(const Duration(milliseconds: 800));

    // Determina o papel do usuário pelo e-mail para facilitar testes
    final role = email.contains('agencia') ? UserRole.consultor : UserRole.cliente;

    _currentUser = UserModel(
      id: 'mock-id-123',
      name: role == UserRole.consultor ? 'Consultor de Teste' : 'Cliente de Teste',
      email: email,
      role: role,
    );

    // Salva tokens fakes para o interceptor não reclamar
    await _secureConfig.saveTokens(
      accessToken: 'mock-access-token',
      refreshToken: 'mock-refresh-token',
    );

    return _currentUser!;
  }

  @override
  Future<UserModel?> getCurrentUser() async => _currentUser;

  @override
  Future<bool> isLoggedIn() async => _currentUser != null;

  @override
  Future<void> logout() async {
    _currentUser = null;
    await _secureConfig.clearTokens();
  }

  @override
  Future<TokenModel> refreshToken(String refreshToken) async {
    return const TokenModel(
      accessToken: 'mock-access-token',
      refreshToken: 'mock-refresh-token',
      expiresIn: 3600,
    );
  }

  @override
  Future<UserModel> register(String name, String email, String password) async {
    return login(email, password);
  }

  @override
  Future<void> saveFcmToken(String token) async {
    // Mock: faz nada
  }
}
