import 'package:flutter_test/flutter_test.dart';
import 'package:cadife_smart_travel/core/utils/validators.dart';

void main() {
  group('AppValidators Logic Tests', () {
    test('Email validator should catch invalid emails', () {
      expect(AppValidators.validateEmail('invalid-email'), 'E-mail inválido');
      expect(AppValidators.validateEmail('test@example.com'), isNull);
      expect(AppValidators.validateEmail(''), isNull); // Opcional no form
    });

    test('Phone validator should require at least 10 digits', () {
      expect(AppValidators.validatePhone(''), 'Telefone obrigatório');
      expect(AppValidators.validatePhone('123'), 'Telefone inválido');
      expect(AppValidators.validatePhone('11988887777'), isNull);
    });

    test('Required validator should catch empty strings', () {
      expect(AppValidators.required(''), 'Campo obrigatório');
      expect(AppValidators.required('John Doe'), isNull);
    });
  });
}
