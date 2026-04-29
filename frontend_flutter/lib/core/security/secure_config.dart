import 'dart:convert';
import 'dart:math';

import 'package:cadife_smart_travel/core/security/secure_strings.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Configuração segura para armazenamento de credenciais e pins de certificado.
///
/// Usa [FlutterSecureStorage] (Keychain iOS / EncryptedSharedPreferences Android).
class SecureConfig {
  SecureConfig({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(
              keyCipherAlgorithm:
                  KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
              storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
            ),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
              synchronizable: false,
            ),
          );

  final FlutterSecureStorage _storage;

  // ── Token Management ───────────────────────────────────

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: SecureStrings.secureStorageKey, value: accessToken),
      _storage.write(key: SecureStrings.refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken() =>
      _storage.read(key: SecureStrings.secureStorageKey);

  Future<String?> getRefreshToken() =>
      _storage.read(key: SecureStrings.refreshTokenKey);

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: SecureStrings.secureStorageKey),
      _storage.delete(key: SecureStrings.refreshTokenKey),
    ]);
  }

  // ── Certificate Pin Storage ────────────────────────────

  Future<void> saveCertificatePins(List<String> pins) async {
    final encoded = jsonEncode(pins);
    await _storage.write(key: SecureStrings.pinningKeyAlias, value: encoded);
  }

  Future<Set<String>> getCertificatePins() async {
    final raw = await _storage.read(key: SecureStrings.pinningKeyAlias);
    if (raw == null) return {};
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<String>().toSet();
  }

  /// Retorna pins de certificado com fallback estático ofuscado.
  ///
  /// 1. Tenta ler pins atualizados do secure storage (rotacionáveis).
  /// 2. Se não houver, usa o fallback estático embutido (ofuscado).
  ///
  /// IMPORTANTE: Substitua [_fallbackPinsObf] pelos pins reais do servidor
  /// antes do deploy de produção.
  Future<List<String>> getCertificatePinsWithFallback() async {
    final dynamicPins = await getCertificatePins();
    if (dynamicPins.isNotEmpty) {
      return dynamicPins.toList();
    }
    // Fallback estático — ofuscado para dificultar extração do binário.
    return _decodeFallbackPins();
  }

  // ── Fallback Pins (obfuscated) ─────────────────────────

  static const String _fallbackPinsObf = '';

  List<String> _decodeFallbackPins() {
    if (_fallbackPinsObf.isEmpty) return [];
    final decoded = SecureStrings.deobfuscate(_fallbackPinsObf);
    return (jsonDecode(decoded) as List<dynamic>).cast<String>();
  }

  // ── Key Generation ─────────────────────────────────────

  /// Gera hash SHA-256 de um certificado DER para comparação com pins.
  static String hashCertificate(List<int> certDer) {
    final digest = sha256.convert(certDer);
    return base64.encode(digest.bytes);
  }

  /// Gera token aleatório para uso como verify token, state, etc.
  static String generateRandomToken([int length = 32]) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Limpa TODO o secure storage (logout, reset).
  Future<void> wipeAll() async {
    await _storage.deleteAll();
  }
}
