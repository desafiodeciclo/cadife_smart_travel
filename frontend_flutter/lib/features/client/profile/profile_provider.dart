import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/client/profile/domain/repositories/profile_port.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profilePortProvider = Provider<ProfilePort>((ref) {
  throw UnimplementedError('Override em ProviderScope');
});

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, AuthUser?>(
      UserProfileNotifier.new,
    );

class UserProfileNotifier extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    final profilePort = ref.watch(profilePortProvider);
    return profilePort.getCurrentUser();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final profilePort = ref.read(profilePortProvider);
      return profilePort.getCurrentUser();
    });
  }

  Future<void> updateProfile({
    String? name,
    List<String>? tipoViagem,
    List<String>? preferencias,
    bool? temPassaporte,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final profilePort = ref.read(profilePortProvider);
      return profilePort.updateProfile(
        name: name,
        tipoViagem: tipoViagem,
        preferencias: preferencias,
        temPassaporte: temPassaporte,
      );
    });
  }
}




