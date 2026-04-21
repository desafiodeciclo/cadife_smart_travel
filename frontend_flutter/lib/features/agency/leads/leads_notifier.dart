import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/api_service.dart';
import '../../auth/auth_notifier.dart';
import 'leads_repository.dart';

final leadsRepositoryProvider = Provider<LeadsRepository>(
  (ref) => LeadsRepository(ref.read(apiServiceProvider)),
);

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
