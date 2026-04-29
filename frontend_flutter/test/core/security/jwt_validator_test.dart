import 'dart:convert';

import 'package:cadife_smart_travel/core/security/jwt_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JwtValidator.isTokenValid', () {
    String buildJwt({required int expOffsetSeconds}) {
      final header =
          base64Url.encode(utf8.encode('{"alg":"none","typ":"JWT"}')).replaceAll('=', '');
      final exp = DateTime.now()
              .toUtc()
              .add(Duration(seconds: expOffsetSeconds))
              .millisecondsSinceEpoch ~/
          1000;
      final payload = base64Url
          .encode(utf8.encode('{"sub":"test","exp":$exp}'))
          .replaceAll('=', '');
      return '$header.$payload.sig';
    }

    test('token válido (exp no futuro) retorna true', () {
      final token = buildJwt(expOffsetSeconds: 3600);
      expect(JwtValidator.isTokenValid(token), isTrue);
    });

    test('token expirado (exp no passado) retorna false', () {
      final token = buildJwt(expOffsetSeconds: -1);
      expect(JwtValidator.isTokenValid(token), isFalse);
    });

    test('null retorna false', () {
      expect(JwtValidator.isTokenValid(null), isFalse);
    });

    test('string vazia retorna false', () {
      expect(JwtValidator.isTokenValid(''), isFalse);
    });

    test('token malformado (sem 3 partes) retorna false', () {
      expect(JwtValidator.isTokenValid('apenas.duaspartes'), isFalse);
      expect(JwtValidator.isTokenValid('nenhum_ponto'), isFalse);
    });

    test('payload sem claim exp retorna false', () {
      final header =
          base64Url.encode(utf8.encode('{"alg":"none"}')).replaceAll('=', '');
      final payload =
          base64Url.encode(utf8.encode('{"sub":"test"}')).replaceAll('=', '');
      final token = '$header.$payload.sig';
      expect(JwtValidator.isTokenValid(token), isFalse);
    });

    test('payload com base64 inválido retorna false', () {
      expect(JwtValidator.isTokenValid('aaa.!!!.bbb'), isFalse);
    });

    test('payload com JSON inválido retorna false', () {
      final invalidPayload =
          base64Url.encode(utf8.encode('not-json')).replaceAll('=', '');
      expect(JwtValidator.isTokenValid('aaa.$invalidPayload.bbb'), isFalse);
    });

    test('token mock gerado pelo MockAuthRepository é válido', () {
      // Simula o formato exato gerado por MockAuthRepository._buildMockJwt()
      final header =
          base64Url.encode(utf8.encode('{"alg":"none","typ":"JWT"}')).replaceAll('=', '');
      final exp =
          DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch ~/
              1000;
      final payloadMap = {'sub': 'mock-id-123', 'exp': exp, 'role': 'cliente', 'iss': 'cadife-mock'};
      final payload =
          base64Url.encode(utf8.encode(jsonEncode(payloadMap))).replaceAll('=', '');
      final token = '$header.$payload.mock-signature';

      expect(JwtValidator.isTokenValid(token), isTrue);
    });
  });
}
