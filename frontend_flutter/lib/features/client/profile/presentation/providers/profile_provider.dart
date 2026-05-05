import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/client/profile/domain/repositories/i_profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Override registrado em: lib/core/di/provider_overrides.dart
final iProfileRepositoryProvider = Provider<IProfileRepository>((ref) {
  throw UnimplementedError('Override em ProviderScope');
});

/// Tracks loading/error state of the save mutation independently of
/// [userProfileProvider]'s fetch state, so the profile screen does not
/// blank out while a PATCH request is in flight.
final profileSaveStateProvider = StateProvider<AsyncValue<void>>(
  (ref) => const AsyncData(null),
);

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

  /// Returns `true` on success, `false` on failure.
  /// Updates [profileSaveStateProvider] instead of blanking [userProfileProvider].
  Future<bool> updateProfile({
    String? name,
    List<String>? tipoViagem,
    List<String>? preferencias,
    bool? temPassaporte,
  }) async {
    final saveNotifier = ref.read(profileSaveStateProvider.notifier);
    saveNotifier.state = const AsyncLoading();
    final repo = ref.read(iProfileRepositoryProvider);
    final result = await repo.updateProfile(
      name: name,
      tipoViagem: tipoViagem,
      preferencias: preferencias,
      temPassaporte: temPassaporte,
    );
    return result.fold(
      (failure) {
        saveNotifier.state = AsyncError(failure, StackTrace.current);
        return false;
      },
      (updatedUser) {
        state = AsyncData(updatedUser);
        saveNotifier.state = const AsyncData(null);
        return true;
      },
    );
  }
}
