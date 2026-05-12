import 'package:riverpod/riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

// Define current user state
class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? avatar;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      avatar: json['avatar'],
    );
  }
}

// Async notifier for fetching user
class CurrentUserNotifier extends AsyncNotifier<User> {
  @override
  Future<User> build() async {
    // Try to get user from /me endpoint
    final apiService = ref.watch(apiServiceProvider);
    try {
      final response = await apiService.get('/users/me');
      return User.fromJson(response);
    } catch (e) {
      print("Failed to fetch user: $e");
      rethrow;
    }
  }

  // Logout function
  Future<void> logout() async {
    final apiService = ref.watch(apiServiceProvider);
    await apiService.clearToken();
    state = const AsyncValue.loading(); // Reset state
  }
}

// Provider
final currentUserProvider = AsyncNotifierProvider<CurrentUserNotifier, User>(
  () => CurrentUserNotifier(),
);
