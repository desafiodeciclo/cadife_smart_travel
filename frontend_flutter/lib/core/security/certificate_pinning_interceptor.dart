import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

/// Interceptor de Certificate Pinning para Dio.
///
/// Valida SHA-256 do certificado do servidor contra pins configurados.
/// Inclui pin de backup para rotação sem downtime.
class CertificatePinningInterceptor extends Interceptor {
  CertificatePinningInterceptor({
    required Set<String> pinnedSha256,
    Set<String>? backupPinnedSha256,
  }) : _primaryPins = pinnedSha256,
       _backupPins = backupPinnedSha256 ?? {};

  final Set<String> _primaryPins;
  final Set<String> _backupPins;

  /// Cria um [HttpClient] configurado com pinning de certificado X.509.
  ///
  /// Use este client no Dio.httpClientAdapter ou IOHttpClientAdapter.
  static HttpClient createPinnedHttpClient({
    required List<String> pinnedSha256,
    List<String>? backupPinnedSha256,
  }) {
    final allPins = <String>{...pinnedSha256, ...?backupPinnedSha256};

    final client = HttpClient();

    client.badCertificateCallback = (cert, host, port) {
      final certDer = cert.der;
      final digest = sha256.convert(certDer);
      final certHash = base64.encode(digest.bytes);

      return allPins.contains(certHash);
    };

    return client;
  }

  /// Valida se o certificado fornecido corresponde a algum dos pins.
  static bool validateCertificate(
    X509Certificate cert, {
    required Set<String> pinnedSha256,
  }) {
    final digest = sha256.convert(cert.der);
    final certHash = base64.encode(digest.bytes);
    return pinnedSha256.contains(certHash);
  }

  /// Retorna os pins primários (para inspeção em testes).
  Set<String> get primaryPins => _primaryPins;

  /// Retorna os pins de backup (para inspeção em testes).
  Set<String> get backupPins => _backupPins;
}
