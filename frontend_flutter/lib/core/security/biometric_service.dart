import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricResult { success, failed, notAvailable, lockedOut }

/// Wrapper sobre `local_auth` com fallback automático para PIN/senha do dispositivo.
///
/// `biometricOnly: false` garante que o diálogo nativo inclui PIN como fallback,
/// cobrindo dispositivos sem biometria configurada.
class BiometricService {
  BiometricService() : _auth = LocalAuthentication();

  final LocalAuthentication _auth;

  Future<bool> isAvailable() => _auth.isDeviceSupported();

  Future<List<BiometricType>> availableBiometrics() =>
      _auth.getAvailableBiometrics();

  Future<BiometricResult> authenticate() async {
    try {
      final supported = await isAvailable();
      if (!supported) return BiometricResult.notAvailable;

      final success = await _auth.authenticate(
        localizedReason: 'Confirme sua identidade para acessar o Cadife',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );
      return success ? BiometricResult.success : BiometricResult.failed;
    } on PlatformException catch (e) {
      return switch (e.code) {
        'LockedOut' || 'PermanentlyLockedOut' => BiometricResult.lockedOut,
        'NotAvailable' || 'NotEnrolled' => BiometricResult.notAvailable,
        _ => BiometricResult.failed,
      };
    }
  }
}
