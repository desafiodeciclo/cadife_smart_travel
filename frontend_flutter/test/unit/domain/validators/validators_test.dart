import 'package:cadife_smart_travel/core/validators/app_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhoneValidator', () {
    test('aceita número brasileiro válido com DDD', () {
      expect(PhoneValidator.validate('+5511999887766'), isNull);
    });

    test('rejeita número sem código do país', () {
      expect(PhoneValidator.validate('11999887766'), isNotNull);
    });

    test('rejeita campo vazio', () {
      expect(PhoneValidator.validate(''), isNotNull);
    });

    test('rejeita número com letras', () {
      expect(PhoneValidator.validate('+551199988abc'), isNotNull);
    });
  });

  group('EmailValidator', () {
    test('aceita e-mail válido', () {
      expect(EmailValidator.validate('teste@cadife.com'), isNull);
    });

    test('rejeita e-mail sem @', () {
      expect(EmailValidator.validate('testecadife.com'), isNotNull);
    });

    test('rejeita e-mail sem domínio', () {
      expect(EmailValidator.validate('teste@'), isNotNull);
    });
  });

  group('DateRangeValidator', () {
    test('aceita intervalo válido', () {
      final start = DateTime(2026, 12, 15);
      final end = DateTime(2026, 12, 22);
      expect(DateRangeValidator.validate(start, end), isNull);
    });

    test('rejeita retorno antes da partida', () {
      final start = DateTime(2026, 12, 22);
      final end = DateTime(2026, 12, 15);
      expect(DateRangeValidator.validate(start, end), isNotNull);
    });
  });
}
