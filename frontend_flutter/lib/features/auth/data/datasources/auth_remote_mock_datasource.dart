import 'dart:convert';

import 'package:cadife_smart_travel/features/auth/data/datasources/i_auth_datasource.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';

class AuthRemoteMockDatasource implements IAuthDatasource {
  AuthRemoteMockDatasource();

  @override
  Future<Map<String, dynamic>> login(String email, String password, {UserRole? profileHint}) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final role = profileHint ??
        (email.contains('agencia') ? UserRole.consultor : UserRole.cliente);

    final userMap = {
      'id': 'mock-id-123',
      'nome': role == UserRole.consultor ? 'Consultor de Teste' : 'Cliente de Teste',
      'email': email,
      'perfil': role.name,
    };

    final tokenMap = {
      'access_token': _buildMockJwt(userMap['id'] as String, role),
      'refresh_token': _buildMockJwt(userMap['id'] as String, role, hours: 168),
      'expires_in': 3600,
    };

    return {
      'user': userMap,
      'token': tokenMap,
    };
  }

  @override
  Future<Map<String, dynamic>?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Simula que o usuário não está em cache no datasource (o repo cuidará do token)
    return null;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'access_token': _buildMockJwt('mock-id-123', UserRole.cliente),
      'refresh_token': _buildMockJwt('mock-id-123', UserRole.cliente, hours: 168),
      'expires_in': 3600,
    };
  }

  @override
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    return login(email, password);
  }

  @override
  Future<void> saveFcmToken(String token) async {}

  @override
  Future<void> forgotPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 1000));
  }

  String _buildMockJwt(String userId, UserRole role, {int hours = 24}) {
    final header = base64Url
        .encode(utf8.encode('{"alg":"none","typ":"JWT"}'))
        .replaceAll('=', '');

    final exp =
        DateTime.now().add(Duration(hours: hours)).millisecondsSinceEpoch ~/
            1000;
    final payloadMap = {
      'sub': userId,
      'exp': exp,
      'role': role.name,
      'iss': 'cadife-mock',
    };
    final payload =
        base64Url.encode(utf8.encode(jsonEncode(payloadMap))).replaceAll('=', '');

    return '$header.$payload.mock-signature';
  }
}
