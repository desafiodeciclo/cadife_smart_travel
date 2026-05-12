import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod/riverpod.dart';

const String API_BASE_URL = "http://localhost:8000"; // Mudar para 10.0.2.2:8000 se estiver no Android Emulator

class ApiService {
  final FlutterSecureStorage _secureStorage;
  final http.Client _client;

  ApiService({
    FlutterSecureStorage? secureStorage,
    http.Client? client,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client();

  /// Get JWT token from secure storage
  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'jwt_token');
  }

  /// Save JWT token to secure storage
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: 'jwt_token', value: token);
  }

  /// Clear JWT token
  Future<void> clearToken() async {
    await _secureStorage.delete(key: 'jwt_token');
  }

  /// Make HTTP GET request with JWT
  Future<dynamic> get(String endpoint) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception("No token found");
      }
      final response = await _client.get(
        Uri.parse('$API_BASE_URL$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await clearToken();
        throw Exception("Unauthorized - token invalid");
      } else {
        throw Exception("HTTP ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      print("GET Error: $e");
      rethrow;
    }
  }

  /// Make HTTP POST request with JWT
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final token = await getToken();
      final response = await _client.post(
        Uri.parse('$API_BASE_URL$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token != null ? 'Bearer $token' : '',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        await clearToken();
        throw Exception("Unauthorized - token invalid");
      } else {
        throw Exception("HTTP ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      print("POST Error: $e");
      rethrow;
    }
  }

  /// Make HTTP PATCH request with JWT
  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    try {
      final token = await getToken();
      final response = await _client.patch(
        Uri.parse('$API_BASE_URL$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        await clearToken();
        throw Exception("Unauthorized - token invalid");
      } else {
        throw Exception("HTTP ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      print("PATCH Error: $e");
      rethrow;
    }
  }

  /// Make HTTP DELETE request with JWT
  Future<dynamic> delete(String endpoint) async {
    try {
      final token = await getToken();
      final response = await _client.delete(
        Uri.parse('$API_BASE_URL$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return response.body.isNotEmpty ? jsonDecode(response.body) : null;
      } else if (response.statusCode == 401) {
        await clearToken();
        throw Exception("Unauthorized - token invalid");
      } else {
        throw Exception("HTTP ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      print("DELETE Error: $e");
      rethrow;
    }
  }
}

// Riverpod provider
final apiServiceProvider = Provider((ref) => ApiService());
