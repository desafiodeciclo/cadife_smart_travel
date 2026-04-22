import 'package:cadife_smart_travel/core/ports/lead_port.dart';
import 'package:cadife_smart_travel/shared/models/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardStats {
  const DashboardStats({
    required this.totalLeads,
    required this.hotLeads,
    required this.warmLeads,
    required this.coldLeads,
    required this.todayAgenda,
    required this.pendingProposals,
  });

  final int totalLeads;
  final int hotLeads;
  final int warmLeads;
  final int coldLeads;
  final int todayAgenda;
  final int pendingProposals;
}

final dashboardLeadPortProvider = Provider<LeadPort>((ref) {
  throw UnimplementedError('Override em ProviderScope');
});

final dashboardStatsProvider = AsyncNotifierProvider<DashboardStatsNotifier, DashboardStats>(
  DashboardStatsNotifier.new,
);

class DashboardStatsNotifier extends AsyncNotifier<DashboardStats> {
  @override
  Future<DashboardStats> build() async {
    final leadPort = ref.watch(dashboardLeadPortProvider);
    final allLeads = await leadPort.getLeads();

    return DashboardStats(
      totalLeads: allLeads.length,
      hotLeads: allLeads.where((l) => l.score == LeadScore.quente).length,
      warmLeads: allLeads.where((l) => l.score == LeadScore.morno).length,
      coldLeads: allLeads.where((l) => l.score == LeadScore.frio).length,
      todayAgenda: 0,
      pendingProposals: 0,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}