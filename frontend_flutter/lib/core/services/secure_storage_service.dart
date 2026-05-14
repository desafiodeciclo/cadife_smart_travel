import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Serviço para armazenar dados sensíveis criptografados.
///
/// Wrapper type-safe ao redor de [FlutterSecureStorage] com suporte a
/// serialização JSON e tratamento de erros consistente.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Armazena um valor criptografado.
  Future<void> write({
    required String key,
    required String value,
  }) async {
    try {
      await _storage.write(key: key, value: value);
    } on Exception catch (e) {
      throw SecureStorageException('Erro ao escrever chave "$key"', e);
    }
  }

  /// Armazena um objeto JSON criptografado.
  Future<void> writeJson({
    required String key,
    required Map<String, dynamic> value,
  }) async {
    try {
      final jsonStr = jsonEncode(value);
      await _storage.write(key: key, value: jsonStr);
    } on Exception catch (e) {
      throw SecureStorageException(
          'Erro ao escrever JSON para chave "$key"', e);
    }
  }

  /// Lê um valor criptografado. Retorna null se não existir.
  Future<String?> read({required String key}) async {
    try {
      return await _storage.read(key: key);
    } on Exception catch (e) {
      throw SecureStorageException('Erro ao ler chave "$key"', e);
    }
  }

  /// Lê um objeto JSON criptografado. Retorna null se não existir.
  Future<Map<String, dynamic>?> readJson({required String key}) async {
    try {
      final jsonStr = await _storage.read(key: key);
      if (jsonStr == null) return null;
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } on Exception catch (e) {
      throw SecureStorageException(
          'Erro ao ler JSON para chave "$key"', e);
    }
  }

  /// Deleta uma chave específica.
  Future<void> delete({required String key}) async {
    try {
      await _storage.delete(key: key);
    } on Exception catch (e) {
      throw SecureStorageException('Erro ao deletar chave "$key"', e);
    }
  }

  /// Deleta TODAS as chaves armazenadas.
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } on Exception catch (e) {
      throw SecureStorageException('Erro ao limpar armazenamento seguro', e);
    }
  }

  /// Verifica se uma chave existe.
  Future<bool> containsKey({required String key}) async {
    try {
      final value = await _storage.read(key: key);
      return value != null;
    } on Exception catch (e) {
      throw SecureStorageException(
          'Erro ao verificar chave "$key"', e);
    }
  }

  /// Lista todas as chaves armazenadas.
  Future<Map<String, String>> readAll() async {
    try {
      return await _storage.readAll();
    } on Exception catch (e) {
      throw SecureStorageException('Erro ao listar todas as chaves', e);
    }
  }
}

/// Exceção específica para erros de armazenamento seguro.
class SecureStorageException implements Exception {
  final String message;
  final Exception? originalException;

  SecureStorageException(this.message, [this.originalException]);

  @override
  String toString() => 'SecureStorageException: $message'
      '${originalException != null ? '\nCausa: $originalException' : ''}';
}
