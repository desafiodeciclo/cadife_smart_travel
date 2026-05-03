import 'package:cadife_smart_travel/features/agency/profile/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, ConsultorProfile>(
  ProfileNotifier.new,
);

class ProfileNotifier extends AsyncNotifier<ConsultorProfile> {
  @override
  Future<ConsultorProfile> build() =>
      ref.read(profileRepositoryProvider).getProfile();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).getProfile(),
    );
  }

  Future<void> updateBio(String bio) async {
    final previous = state;
    state = previous.whenData((p) => p.copyWith(bio: bio));
    try {
      final updated = await ref.read(profileRepositoryProvider).updateBio(bio);
      state = AsyncData(updated);
    } catch (e, st) {
      state = previous;
      Error.throwWithStackTrace(e, st);
    }
  }
}
