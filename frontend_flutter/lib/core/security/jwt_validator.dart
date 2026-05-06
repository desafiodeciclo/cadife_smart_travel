import 'dart:convert';

/// Valida tokens JWT localmente decodificando o claim `exp` do payload.
///
/// Não verifica assinatura — apenas determina se o token está estruturalmente
/// correto e não expirou. O backend valida a assinatura em cada request autenticada.
class JwtValidator {
  JwtValidator._();

  /// Retorna `true` se [rawToken] é um JWT não-expirado.
  ///
  /// Retorna `false` para null, vazio, malformado ou expirado.
  static bool isTokenValid(String? rawToken) {
    if (rawToken == null || rawToken.isEmpty) return false;
    try {
      final parts = rawToken.split('.');
      if (parts.length != 3) return false;

      var encoded = parts[1];
      // Base64URL → Base64: restitui padding removido pela spec JWT
      encoded += '=' * ((4 - encoded.length % 4) % 4);

      final decoded = utf8.decode(base64Url.decode(encoded));
      final claims = jsonDecode(decoded) as Map<String, dynamic>;

      final exp = claims['exp'];
      if (exp == null) return false;

      final expiry = DateTime.fromMillisecondsSinceEpoch(
        (exp as num).toInt() * 1000,
        isUtc: true,
      );
      return DateTime.now().toUtc().isBefore(expiry);
    } on Object catch (_) {
      // Token malformado — trata como não autenticado sem propagar erro
      return false;
    }
  }
}
