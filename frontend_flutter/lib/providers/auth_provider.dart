import 'package:riverpod/riverpod.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../features/auth/presentation/providers/auth_notifier.dart';
import '../features/auth/domain/entities/auth_user.dart';

// Async notifier for fetching user
class CurrentUserNotifier extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    // Escuta o estado global de autenticaÃ§Ã£o
    final authState = ref.watch(authNotifierProvider);
    
    // Se o AuthNotifier jÃ¡ tem o usuÃ¡rio (vindo do login), usa ele imediatamente!
    if (authState.hasValue && authState.value != null) {
      debugPrint('👤 [AUTH] UsuÃ¡rio atualizado: ${authState.value?.name}');
      return authState.value;
    }

    final apiService = ref.watch(apiServiceProvider);
    try {
      debugPrint('📡 [API] Buscando perfil em /users/me...');
      final response = await apiService.get('/users/me');
      final user = AuthUser.fromJson(response);
      debugPrint('✅ [AUTH] Perfil carregado do servidor: ${user.name}');
      return user;
    } catch (e) {
      debugPrint('❌ [AUTH] Erro ao buscar perfil: $e');
      return null;
    }
  }

  // Logout REALMENTE LIMPO
  Future<void> logout() async {
    debugPrint('🚪 [AUTH] Iniciando Logout completo...');
    final apiService = ref.read(apiServiceProvider);
    
    // 1. Limpa o token no disco
    await apiService.clearToken();
    
    // 2. Invalida os providers para limpar o cache da memÃ³ria
    ref.invalidate(authNotifierProvider);
    ref.invalidateSelf();
    
    debugPrint('✅ [AUTH] Cache limpo com sucesso.');
  }
}

// Provider
final currentUserProvider = AsyncNotifierProvider<CurrentUserNotifier, AuthUser?>(
  () => CurrentUserNotifier(),
);
