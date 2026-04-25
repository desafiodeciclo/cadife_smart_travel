import 'dart:convert';

import 'package:cadife_smart_travel/features/auth/auth_notifier.dart';
import 'package:cadife_smart_travel/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ── Mock ──────────────────────────────────────────────────────────────────────

class MockApiService extends Mock implements ApiService {}

// ── JWT helper ────────────────────────────────────────────────────────────────

/// Constrói um JWT mínimo e válido para testes.
/// jwt_decoder só decodifica base64 do payload — nunca verifica a assinatura.
String _buildJwt(Map<String, dynamic> claims, {bool expired = false}) {
  final now = DateTime.now();
  final exp = expired
      ? now.subtract(const Duration(hours: 1))
      : now.add(const Duration(hours: 1));

  final payload = {
    ...claims,
    'exp': exp.millisecondsSinceEpoch ~/ 1000,
    'iat': now.millisecondsSinceEpoch ~/ 1000,
  };

  String b64(String s) =>
      base64Url.encode(utf8.encode(s)).replaceAll('=', '');

  final header = b64('{"alg":"HS256","typ":"JWT"}');
  final body = b64(jsonEncode(payload));
  return '$header.$body.fakesignature';
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockApiService mockApi;
  late ProviderContainer container;

  setUp(() {
    mockApi = MockApiService();
    container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((_) => AuthNotifier(mockApi)),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('AuthNotifier.checkSession()', () {
    test('1. Token nulo → estado permanece isLoggedIn: false', () async {
      when(() => mockApi.getAccessToken()).thenAnswer((_) async => null);

      await container.read(authProvider.notifier).checkSession();

      expect(container.read(authProvider).isLoggedIn, isFalse);
      verifyNever(() => mockApi.clearTokens());
    });

    test('2. Token válido com claim perfil → isLoggedIn: true e userPerfil correto', () async {
      final token = _buildJwt({'perfil': 'agencia'});
      when(() => mockApi.getAccessToken()).thenAnswer((_) async => token);

      await container.read(authProvider.notifier).checkSession();

      final state = container.read(authProvider);
      expect(state.isLoggedIn, isTrue);
      expect(state.userPerfil, equals('agencia'));
      verifyNever(() => mockApi.clearTokens());
    });

    test('3. Token válido com claim role → isLoggedIn: true e userPerfil via role', () async {
      final token = _buildJwt({'role': 'cliente'});
      when(() => mockApi.getAccessToken()).thenAnswer((_) async => token);

      await container.read(authProvider.notifier).checkSession();

      final state = container.read(authProvider);
      expect(state.isLoggedIn, isTrue);
      expect(state.userPerfil, equals('cliente'));
    });

    test('4. Token expirado → clearTokens() chamado, isLoggedIn: false', () async {
      final token = _buildJwt({'perfil': 'agencia'}, expired: true);
      when(() => mockApi.getAccessToken()).thenAnswer((_) async => token);
      when(() => mockApi.clearTokens()).thenAnswer((_) async {});

      await container.read(authProvider.notifier).checkSession();

      expect(container.read(authProvider).isLoggedIn, isFalse);
      verify(() => mockApi.clearTokens()).called(1);
    });

    test('5. Token malformado → clearTokens() chamado, isLoggedIn: false', () async {
      when(() => mockApi.getAccessToken())
          .thenAnswer((_) async => 'isso.nao.e.um.jwt.valido');
      when(() => mockApi.clearTokens()).thenAnswer((_) async {});

      await container.read(authProvider.notifier).checkSession();

      expect(container.read(authProvider).isLoggedIn, isFalse);
      verify(() => mockApi.clearTokens()).called(1);
    });
  });
}
