import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/client/profile/domain/repositories/i_profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final iProfileRepositoryProvider = Provider<IProfileRepository>((ref) {
  throw UnimplementedError('Override em ProviderScope');
});

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, AuthUser?>(
      UserProfileNotifier.new,
    );

class UserProfileNotifier extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    final repo = ref.watch(iProfileRepositoryProvider);
    final result = await repo.getCurrentUser();
    return result.fold(
      (failure) => throw failure,
      (user) => user,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final repo = ref.read(iProfileRepositoryProvider);
    final result = await repo.getCurrentUser();
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      AsyncData.new,
    );
  }

  Future<void> updateProfile({
    String? name,
    List<String>? tipoViagem,
    List<String>? preferencias,
    bool? temPassaporte,
  }) async {
    state = const AsyncLoading();
    final repo = ref.read(iProfileRepositoryProvider);
    final result = await repo.updateProfile(
      name: name,
      tipoViagem: tipoViagem,
      preferencias: preferencias,
      temPassaporte: temPassaporte,
    );
    
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      AsyncData.new,
    );
  }
}





