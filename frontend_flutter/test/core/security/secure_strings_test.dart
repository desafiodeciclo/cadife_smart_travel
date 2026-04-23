import 'package:cadife_smart_travel/core/security/secure_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SecureStrings', () {
    test('deobfuscate deve restaurar string original após obfuscate', () {
      const original = 'certificate_pins';
      final obfuscated = SecureStrings.obfuscate(original);
      final restored = SecureStrings.deobfuscate(obfuscated);
      expect(restored, equals(original));
    });

    test('deobfuscate de constante _secureStorageKeyObf deve ser cadife_secure_key', () {
      expect(SecureStrings.secureStorageKey, equals('cadife_secure_key'));
    });

    test('deobfuscate de constante _pinningKeyAliasObf deve ser certificate_pins', () {
      expect(SecureStrings.pinningKeyAlias, equals('certificate_pins'));
    });

    test('deobfuscate de constante _refreshTokenKeyObf deve ser refresh_token_key', () {
      expect(SecureStrings.refreshTokenKey, equals('refresh_token_key'));
    });

    test('strings ofuscadas devem ser diferentes do original', () {
      const original = 'test_string';
      final obfuscated = SecureStrings.obfuscate(original);
      expect(obfuscated, isNot(equals(original)));
    });
  });
}
