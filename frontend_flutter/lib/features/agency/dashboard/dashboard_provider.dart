import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/repositories/lead_port.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardStats {
  const DashboardStats({
    required this.totalLeads,
    required this.hotLeads,
    required this.warmLeads,
    required this.coldLeads,
    required this.todayAgenda,
    required this.pendingProposals,
    required this.taxaQualificacao,
    required this.taxaConversao,
    required this.leadsPorStatus,
  });

  final int totalLeads;
  final int hotLeads;
  final int warmLeads;
  final int coldLeads;
  final int todayAgenda;
  final int pendingProposals;
  final double taxaQualificacao;
  final double taxaConversao;
  final Map<String, int> leadsPorStatus;
}

final dashboardLeadPortProvider = Provider<LeadPort>((ref) {
  throw UnimplementedError('Override em ProviderScope');
});

final dashboardStatsProvider =
    AsyncNotifierProvider<DashboardStatsNotifier, DashboardStats>(
      DashboardStatsNotifier.new,
    );

class DashboardStatsNotifier extends AsyncNotifier<DashboardStats> {
  @override
  Future<DashboardStats> build() async {
    final leadPort = ref.watch(dashboardLeadPortProvider);
    final allLeads = await leadPort.getLeads();

    final qualificados = allLeads.where((l) => l.status == LeadStatus.qualificado).length;
    final proposta = allLeads.where((l) => l.status == LeadStatus.proposta).length;
    final fechado = allLeads.where((l) => l.status == LeadStatus.fechado).length;

    final taxaQualificacao = allLeads.isEmpty
        ? 0.0
        : (qualificados + proposta + fechado) / allLeads.length * 100;

    final taxaConversao = allLeads.isEmpty
        ? 0.0
        : fechado / allLeads.length * 100;

    final leadsPorStatus = {
      'novo': allLeads.where((l) => l.status == LeadStatus.novo).length,
      'qualificado': qualificados,
      'proposta': proposta,
      'fechado': fechado,
    };

    return DashboardStats(
      totalLeads: allLeads.length,
      hotLeads: allLeads.where((l) => l.score == LeadScore.quente).length,
      warmLeads: allLeads.where((l) => l.score == LeadScore.morno).length,
      coldLeads: allLeads.where((l) => l.score == LeadScore.frio).length,
      todayAgenda: 0,
      pendingProposals: 0,
      taxaQualificacao: taxaQualificacao,
      taxaConversao: taxaConversao,
      leadsPorStatus: leadsPorStatus,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}




