import 'dart:convert';
import 'dart:typed_data';

/// Ofuscação leve de strings sensíveis usando XOR + Base64.
///
/// As strings ofuscadas são armazenadas como constantes no código fonte.
/// Em runtime, [deobfuscate] restaura o valor original.
///
/// Isso dificulta a extração direta via `strings` do binário,
/// mas NÃO é criptografia forte — o objetivo é mitigar leitura casual.
class SecureStrings {
  SecureStrings._();

  /// Chave de XOR fixa (8 bytes). Deve ser modificada por build flavor se necessário.
  static const List<int> _key = <int>[0x5A, 0x3C, 0x7F, 0x12, 0x44, 0x88, 0xAA, 0x33];

  // ── Obfuscated Constants ───────────────────────────────

  /// `cadife_secure_key`
  static const String _secureStorageKeyObf = 'OV0beyLt9UA/XwpgIdfBViM=';

  /// `certificate_pins`
  static const String _pinningKeyAliasObf = 'OVkNZi3uw1A7SBpNNOHEQA==';

  /// `refresh_token_key`
  static const String _refreshTokenKeyObf = 'KFkZYCH7wmwuUxR3KtfBViM=';

  // ── Public De-obfuscated Accessors ─────────────────────

  static String get secureStorageKey => deobfuscate(_secureStorageKeyObf);
  static String get pinningKeyAlias => deobfuscate(_pinningKeyAliasObf);
  static String get refreshTokenKey => deobfuscate(_refreshTokenKeyObf);

  // ── Core Logic ─────────────────────────────────────────

  /// De-ofusca uma string [obfuscated] codificada em Base64(XOR).
  static String deobfuscate(String obfuscated) {
    final bytes = base64Decode(obfuscated);
    final result = Uint8List(bytes.length);
    for (var i = 0; i < bytes.length; i++) {
      result[i] = bytes[i] ^ _key[i % _key.length];
    }
    return utf8.decode(result);
  }

  /// Ofusca uma string [input] para Base64(XOR). Usado apenas em build-time.
  static String obfuscate(String input) {
    final bytes = utf8.encode(input);
    final result = Uint8List(bytes.length);
    for (var i = 0; i < bytes.length; i++) {
      result[i] = bytes[i] ^ _key[i % _key.length];
    }
    return base64Encode(result);
  }
}
