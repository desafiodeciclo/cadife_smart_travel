import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Verificador de conectividade de rede.
///
/// Fornece stream de mudanças e snapshot atual de conectividade.
class NetworkInfo {
  NetworkInfo({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Retorna `true` se o device está online (WiFi ou Mobile).
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.ethernet);
  }

  /// Stream de mudanças de conectividade.
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((results) {
      return results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet);
    });
  }

  /// Retorna o tipo de conexão atual.
  Future<ConnectivityResult> get connectionType async {
    final results = await _connectivity.checkConnectivity();
    if (results.isEmpty) return ConnectivityResult.none;
    return results.first;
  }
}
