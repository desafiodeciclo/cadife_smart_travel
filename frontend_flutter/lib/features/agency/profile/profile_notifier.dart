import 'package:cadife_smart_travel/core/ports/consultor_port.dart';
import 'package:cadife_smart_travel/features/agency/profile/consultor_profile_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final consultorPortProvider = Provider<ConsultorPort>((ref) {
  throw UnimplementedError('Override em ProviderScope');
});

// ── Profile ──────────────────────────────────────────────────────────────────

final consultorProfileProvider =
    AsyncNotifierProvider<ConsultorProfileNotifier, ConsultorProfile>(
  ConsultorProfileNotifier.new,
);

class ConsultorProfileNotifier
    extends AsyncNotifier<ConsultorProfile> {
  @override
  Future<ConsultorProfile> build() =>
      ref.watch(consultorPortProvider).getProfile();

  Future<void> updateBio(String bio) async {
    final previous = state.valueOrNull;
    if (previous == null) return;

    // Optimistic update
    state = AsyncData(previous.copyWith(bio: bio));

    try {
      final updated =
          await ref.read(consultorPortProvider).updateBio(bio);
      state = AsyncData(updated);
    } catch (e, st) {
      state = AsyncData(previous);
      state = AsyncError(e, st);
    }
  }
}

// ── Goals ─────────────────────────────────────────────────────────────────────

final saleGoalsProvider =
    AsyncNotifierProvider<SaleGoalsNotifier, List<SaleGoal>>(
  SaleGoalsNotifier.new,
);

class SaleGoalsNotifier extends AsyncNotifier<List<SaleGoal>> {
  @override
  Future<List<SaleGoal>> build() =>
      ref.watch(consultorPortProvider).getGoals();
}
