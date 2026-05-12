import 'package:riverpod/riverpod.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../features/auth/presentation/providers/auth_notifier.dart';

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
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'UsuÃ¡rio',
      email: json['email'] ?? '',
      role: json['role'] ?? 'client',
      avatar: json['avatar'],
    );
  }
}

// Async notifier for fetching user
class CurrentUserNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final apiService = ref.watch(apiServiceProvider);
    
    // Escuta o estado de autenticaÃ§Ã£o
    final authState = ref.watch(authNotifierProvider);
    
    // Se nÃ£o estiver logado no Notifier principal, nem tenta buscar
    if (authState.valueOrNull == null) {
      return null;
    }

    try {
      debugPrint('📡 [API] Buscando dados do usuÃ¡rio em /users/me...');
      
      // Pequeno delay para garantir que o interceptor de Auth tenha o token novo
      await Future.delayed(const Duration(milliseconds: 500));
      
      final response = await apiService.get('/users/me');
      final user = User.fromJson(response);
      debugPrint('✅ [AUTH] Nome carregado: ${user.name}');
      return user;
    } catch (e) {
      debugPrint('❌ [AUTH] Erro ao buscar usuÃ¡rio: $e');
      
      // Se deu erro, tenta invalidar para buscar de novo em 2 segundos
      Future.delayed(const Duration(seconds: 2), () {
        ref.invalidateSelf();
      });
      
      return null;
    }
  }

  // Logout function
  Future<void> logout() async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.clearToken();
    ref.invalidate(authNotifierProvider);
    ref.invalidateSelf();
  }
}

// Provider
final currentUserProvider = AsyncNotifierProvider<CurrentUserNotifier, User?>(
  () => CurrentUserNotifier(),
);
