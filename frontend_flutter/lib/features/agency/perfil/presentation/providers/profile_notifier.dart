import 'package:cadife_smart_travel/features/agency/perfil/domain/entities/consultor_profile_models.dart';
import 'package:cadife_smart_travel/features/agency/perfil/domain/repositories/i_consultor_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Override registrado em: lib/core/di/provider_overrides.dart
final iConsultorRepositoryProvider = Provider<IConsultorRepository>((ref) {
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
    final result = await ref.watch(iConsultorRepositoryProvider).getProfile();
    return result.fold<ConsultorProfile>(
      (failure) => throw failure,
      (profile) => profile,
    );
  }

  Future<void> updateBio(String bio) async {
    final previous = state.valueOrNull;
    if (previous == null) return;

    // Optimistic update
    state = AsyncData(previous.copyWith(bio: bio));

    final result = await ref.read(iConsultorRepositoryProvider).updateBio(bio);
    state = result.fold(
      (failure) {
        // Revert on error
        return AsyncError(failure, StackTrace.current);
      },
      AsyncData.new,
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
    final result = await ref.watch(iConsultorRepositoryProvider).getGoals();
    return result.fold<List<SaleGoal>>(
      (failure) => throw failure,
      (goals) => goals,
    );
  }
}


