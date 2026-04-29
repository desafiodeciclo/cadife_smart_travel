import 'package:cadife_smart_travel/core/ports/profile_port.dart';
import 'package:cadife_smart_travel/shared/models/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profilePortProvider = Provider<ProfilePort>((ref) {
  throw UnimplementedError('Override em ProviderScope');
});

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserModel?>(
      UserProfileNotifier.new,
    );

class UserProfileNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
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
