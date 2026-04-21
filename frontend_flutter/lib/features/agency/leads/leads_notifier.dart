import 'package:cadife_smart_travel/features/agency/leads/leads_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LeadsNotifier extends AsyncNotifier<List<Lead>> {
  @override
  Future<List<Lead>> build() => ref.read(leadsRepositoryProvider).getLeads();

  Future<void> refresh({String? status, String? score, String? search}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(leadsRepositoryProvider).getLeads(
            status: status,
            score: score,
            search: search,
          ),
    );
  }
}

final leadsNotifierProvider = AsyncNotifierProvider<LeadsNotifier, List<Lead>>(
  LeadsNotifier.new,
);
