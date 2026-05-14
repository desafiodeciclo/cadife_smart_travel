import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

// Async notifier for fetching user
class CurrentUserNotifier extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    // Escuta o estado global de autenticação
    final authState = ref.watch(authNotifierProvider);
    
    // Se o AuthNotifier já tem o usuário (vindo do login), usa ele imediatamente!
    if (authState.hasValue && authState.value != null) {
      debugPrint('👤 [AUTH] Usuário atualizado: ${authState.value?.name}');
      return authState.value;
    }

    final repository = GetIt.I<IAuthRepository>();
    final result = await repository.getUserProfile();
    return result.fold(
      (failure) {
        debugPrint('❌ [AUTH] Erro ao buscar perfil: ${failure.message}');
        return null;
      },
      (user) {
        debugPrint('✅ [AUTH] Perfil carregado do servidor: ${user?.name}');
        return user;
      },
    );
  }

  // Logout REALMENTE LIMPO
  Future<void> logout() async {
    debugPrint('🚪 [AUTH] Iniciando Logout completo...');
    
    // AuthNotifier.logout already clears tokens via SecureConfig and calls remote logout.
    await ref.read(authNotifierProvider.notifier).logout();
    ref.invalidateSelf();
    
    debugPrint('✅ [AUTH] Cache limpo com sucesso.');
  }
}

// Provider
final currentUserProvider = AsyncNotifierProvider<CurrentUserNotifier, AuthUser?>(
  CurrentUserNotifier.new,
);
