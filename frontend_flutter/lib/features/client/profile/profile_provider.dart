import 'package:cadife_smart_travel/core/ports/auth_port.dart';
import 'package:cadife_smart_travel/shared/models/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileAuthProvider = Provider<AuthPort>((ref) {
  throw UnimplementedError('Override em ProviderScope');
});

final userProfileProvider = AsyncNotifierProvider<UserProfileNotifier, UserModel?>(
  UserProfileNotifier.new,
);

class UserProfileNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    final authPort = ref.watch(profileAuthProvider);
    return authPort.getCurrentUser();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final authPort = ref.read(profileAuthProvider);
      return authPort.getCurrentUser();
    });
  }
}