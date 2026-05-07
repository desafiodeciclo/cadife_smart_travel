import 'dart:convert';

class JwtUtils {
  JwtUtils._();

  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      final padded = payload.padRight((payload.length + 3) & ~3, '=');
      final bytes = base64Url.decode(padded);
      return json.decode(utf8.decode(bytes)) as Map<String, dynamic>;
    } on Object catch (_) {
      return null;
    }
  }

  static String? extractRole(String token) =>
      decodePayload(token)?['role'] as String?;

  static bool isExpired(String token) {
    final payload = decodePayload(token);
    if (payload == null) return true;
    final exp = payload['exp'];
    if (exp == null) return false;
    final expTime = DateTime.fromMillisecondsSinceEpoch((exp as int) * 1000);
    return DateTime.now().isAfter(expTime);
  }
}
