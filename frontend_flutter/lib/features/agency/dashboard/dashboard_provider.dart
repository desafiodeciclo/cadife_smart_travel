import 'package:cadife_smart_travel/features/agency/agenda/presentation/providers/agenda_provider.dart';
import 'package:cadife_smart_travel/features/agency/leads/data/providers/leads_data_providers.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/propostas/domain/entities/proposta.dart';
import 'package:cadife_smart_travel/features/agency/propostas/presentation/providers/proposals_provider.dart';
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

final dashboardStatsProvider =
    AsyncNotifierProvider<DashboardStatsNotifier, DashboardStats>(
      DashboardStatsNotifier.new,
    );

class DashboardStatsNotifier extends AsyncNotifier<DashboardStats> {
  @override
  Future<DashboardStats> build() async {
    final leadRepository = ref.watch(leadsRepositoryProvider);
    final agendaRepository = ref.watch(agendaRepositoryProvider);
    final proposalsRepository = ref.watch(iProposalsRepositoryProvider);

    final allLeadsResult = await leadRepository.getLeads();
    final allLeads = allLeadsResult.fold(
      (failure) => throw failure,
      (leads) => leads,
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final agendaResult = await agendaRepository.getAgenda(date: today);
    final todayAgendaCount = agendaResult.fold(
      (_) => 0,
      (items) => items.length,
    );

    final proposalsResult = await proposalsRepository.getProposals();
    final pendingProposalsCount = proposalsResult.fold(
      (_) => 0,
      (proposals) => proposals
          .where(
            (p) =>
                p.status == ProposalStatus.enviada ||
                p.status == ProposalStatus.rascunho,
          )
          .length,
    );

    final qualificados =
        allLeads.where((l) => l.status == LeadStatus.qualificado).length;
    final proposta =
        allLeads.where((l) => l.status == LeadStatus.proposta).length;
    final fechado =
        allLeads.where((l) => l.status == LeadStatus.fechado).length;

    final taxaQualificacao = allLeads.isEmpty
        ? 0.0
        : (qualificados + proposta + fechado) / allLeads.length * 100;

    final taxaConversao = allLeads.isEmpty
        ? 0.0
        : fechado / allLeads.length * 100;

    return DashboardStats(
      totalLeads: allLeads.length,
      hotLeads: allLeads.where((l) => l.score == LeadScore.quente).length,
      warmLeads: allLeads.where((l) => l.score == LeadScore.morno).length,
      coldLeads: allLeads.where((l) => l.score == LeadScore.frio).length,
      todayAgenda: todayAgendaCount,
      pendingProposals: pendingProposalsCount,
      taxaQualificacao: taxaQualificacao,
      taxaConversao: taxaConversao,
      leadsPorStatus: {
        'novo': allLeads.where((l) => l.status == LeadStatus.novo).length,
        'qualificado': qualificados,
        'proposta': proposta,
        'fechado': fechado,
      },
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}
