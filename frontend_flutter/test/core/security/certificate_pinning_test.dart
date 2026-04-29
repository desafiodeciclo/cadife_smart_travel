import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cadife_smart_travel/core/security/certificate_pinning_interceptor.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockX509Certificate extends Mock implements X509Certificate {}

void main() {
  group('CertificatePinningInterceptor', () {
    late Uint8List fakeCertDer;
    late String validPin;
    late String backupPin;
    late String invalidPin;

    setUp(() {
      fakeCertDer = Uint8List.fromList(List<int>.generate(64, (i) => i));
      validPin = base64.encode(sha256.convert(fakeCertDer).bytes);

      final backupCertDer = Uint8List.fromList(List<int>.generate(64, (i) => i + 1));
      backupPin = base64.encode(sha256.convert(backupCertDer).bytes);

      invalidPin = base64.encode(sha256.convert([1, 2, 3]).bytes);
    });

    test('validateCertificate retorna true para pin válido', () {
      final cert = _MockX509Certificate();
      when(() => cert.der).thenReturn(fakeCertDer);

      final result = CertificatePinningInterceptor.validateCertificate(
        cert,
        pinnedSha256: {validPin},
      );
      expect(result, isTrue);
    });

    test('validateCertificate retorna false para pin inválido', () {
      final cert = _MockX509Certificate();
      when(() => cert.der).thenReturn(fakeCertDer);

      final result = CertificatePinningInterceptor.validateCertificate(
        cert,
        pinnedSha256: {invalidPin},
      );
      expect(result, isFalse);
    });

    test('validateCertificate aceita backup pin quando primário não corresponde', () {
      final cert = _MockX509Certificate();
      when(() => cert.der).thenReturn(fakeCertDer);

      final result = CertificatePinningInterceptor.validateCertificate(
        cert,
        pinnedSha256: {invalidPin, validPin},
      );
      expect(result, isTrue);
    });

    test('validateCertificate rejeita quando nenhum pin corresponde', () {
      final cert = _MockX509Certificate();
      when(() => cert.der).thenReturn(fakeCertDer);

      final result = CertificatePinningInterceptor.validateCertificate(
        cert,
        pinnedSha256: {invalidPin, backupPin},
      );
      expect(result, isFalse);
    });

    test('primaryPins e backupPins são expostos corretamente', () {
      final interceptor = CertificatePinningInterceptor(
        pinnedSha256: {validPin},
        backupPinnedSha256: {backupPin},
      );
      expect(interceptor.primaryPins, equals({validPin}));
      expect(interceptor.backupPins, equals({backupPin}));
    });
  });
}
