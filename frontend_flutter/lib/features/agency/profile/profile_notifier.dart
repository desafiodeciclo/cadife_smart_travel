import 'package:cadife_smart_travel/features/agency/profile/consultor_profile_models.dart';
import 'package:cadife_smart_travel/features/agency/profile/domain/repositories/i_consultor_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final IConsultorRepositoryProvider = Provider<IConsultorRepository>((ref) {
  throw UnimplementedError('Override em ProviderScope');
});

// â”€â”€ Profile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

final consultorProfileProvider =
    AsyncNotifierProvider<ConsultorProfileNotifier, ConsultorProfile>(
  ConsultorProfileNotifier.new,
);

class ConsultorProfileNotifier
    extends AsyncNotifier<ConsultorProfile> {
  @override
  Future<ConsultorProfile> build() async {
    final result = await ref.watch(IConsultorRepositoryProvider).getProfile();
    return result.fold(
      (failure) => throw failure,
      (profile) => profile,
    );
  }

  Future<void> updateBio(String bio) async {
    final previous = state.valueOrNull;
    if (previous == null) return;

    // Optimistic update
    state = AsyncData(previous.copyWith(bio: bio));

    final result = await ref.read(IConsultorRepositoryProvider).updateBio(bio);
    state = result.fold(
      (failure) {
        // Revert on error
        return AsyncError(failure, StackTrace.current);
      },
      (updated) => AsyncData(updated),
    );
  }
}

// ── Goals ─────────────────────────────────────────────────────────────────────

final saleGoalsProvider =
    AsyncNotifierProvider<SaleGoalsNotifier, List<SaleGoal>>(
  SaleGoalsNotifier.new,
);

class SaleGoalsNotifier extends AsyncNotifier<List<SaleGoal>> {
  @override
  Future<List<SaleGoal>> build() async {
    final result = await ref.watch(IConsultorRepositoryProvider).getGoals();
    return result.fold(
      (failure) => throw failure,
      (goals) => goals,
    );
  }
}


