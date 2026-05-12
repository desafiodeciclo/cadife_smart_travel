import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/agenda/presentation/providers/agenda_provider.dart';
import 'package:cadife_smart_travel/features/agency/dashboard/dashboard_provider.dart';
import 'package:cadife_smart_travel/features/agency/dashboard/widgets/pipeline_status_section.dart';
import 'package:cadife_smart_travel/features/agency/dashboard/widgets/recent_leads_section.dart';
import 'package:cadife_smart_travel/features/agency/dashboard/widgets/upcoming_meetings_section.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/providers/leads_notifier.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/widgets/lead_card.dart';
import 'package:cadife_smart_travel/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:cadife_smart_travel/providers/dashboard_provider.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/error_state/app_error_state.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/error_state/error_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageScaffold(
      showProfile: false,
      body: _buildDashboardContent(context, ref),
    );
  }

  Widget _buildDashboardContent(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);

    return metricsAsync.when(
      data: (metrics) => _buildMetrics(context, metrics, ref),
      loading: () => const _LoadingShimmer(),
      error: (e, st) => AppErrorState(
        type: ErrorType.genericError,
        customSubtitle: e.toString(),
        onRetry: () => ref.read(dashboardMetricsProvider.notifier).refresh(),
      ),
    );
  }

  Widget _buildMetrics(
    BuildContext context,
    DashboardMetrics metrics,
    WidgetRef ref,
  ) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final leadsAsync = ref.watch(leadsNotifierProvider);
    final agendaAsync = ref.watch(agendaProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardMetricsProvider);
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(leadsNotifierProvider);
        ref.invalidate(agendaProvider);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // AppBar
          const SliverToBoxAdapter(
            child: CadifeAppBar(
              title: 'Dashboard',
              actions: [
                NotificationBell(),
                SizedBox(width: 8),
              ],
            ),
          ),

          // Metrics grid
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildListDelegate([
                _MetricCard(
                  label: 'Leads Qualificados',
                  value: '${metrics.leadsQualified}',
                  icon: LucideIcons.userCheck,
                  color: AppColors.primary,
                ),
                _MetricCard(
                  label: 'Taxa de Conversão',
                  value: '${metrics.conversionRate.toStringAsFixed(1)}%',
                  icon: LucideIcons.trendingUp,
                  color: AppColors.success,
                ),
                _MetricCard(
                  label: 'Receita Mensal',
                  value: 'R\$ ${metrics.monthlyRevenue.toStringAsFixed(0)}',
                  icon: LucideIcons.banknote,
                  color: AppColors.info,
                ),
                _MetricCard(
                  label: 'Clientes Ativos',
                  value: '${metrics.activeClients}',
                  icon: LucideIcons.users,
                  color: AppColors.warning,
                ),
              ]),
            ),
          ),

          // Pipeline Status
          SliverToBoxAdapter(
            child: statsAsync.maybeWhen(
              data: (stats) => PipelineStatusSection(
                leadsPorStatus: stats.leadsPorStatus,
                onStageTap: (stageKey) => _showLeadsByStatus(context, ref, stageKey),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Recent Leads
          SliverToBoxAdapter(
            child: leadsAsync.maybeWhen(
              data: (leads) => RecentLeadsSection(leads: leads),
              orElse: () => const SizedBox.shrink(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Upcoming Meetings
          SliverToBoxAdapter(
            child: agendaAsync.maybeWhen(
              data: (agendamentos) =>
                  UpcomingMeetingsSection(agendamentos: agendamentos),
              orElse: () => const SizedBox.shrink(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }
  void _showLeadsByStatus(
      BuildContext context, WidgetRef ref, String stageKey) {
    final status = _mapStageToStatus(stageKey);
    final leadsAsync = ref.read(leadsNotifierProvider);

    final filteredLeads = leadsAsync.maybeWhen(
      data: (leads) => leads.where((l) => l.status == status).toList(),
      orElse: () => <Lead>[],
    );

    final stageName = _mapStageToName(stageKey);
    final stageColor = _mapStageToColor(stageKey);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _LeadsStatusDrawer(
        stageName: stageName,
        stageColor: stageColor,
        leads: filteredLeads,
      ),
    );
  }

  LeadStatus _mapStageToStatus(String stageKey) => switch (stageKey) {
        'novo' => LeadStatus.novo,
        'emAtendimento' => LeadStatus.emAtendimento,
        'qualificado' => LeadStatus.qualificado,
        'proposta' => LeadStatus.proposta,
        'fechado' => LeadStatus.fechado,
        _ => LeadStatus.novo,
      };

  String _mapStageToName(String stageKey) => switch (stageKey) {
        'novo' => 'Novo',
        'emAtendimento' => 'Em Atendimento',
        'qualificado' => 'Qualificado',
        'proposta' => 'Proposta',
        'fechado' => 'Fechado',
        _ => 'Leads',
      };

  Color _mapStageToColor(String stageKey) => switch (stageKey) {
        'novo' => const Color(0xFF3B82F6),
        'emAtendimento' => const Color(0xFFF97316),
        'qualificado' => const Color(0xFF8B5CF6),
        'proposta' => const Color(0xFF06B6D4),
        'fechado' => const Color(0xFF22C55E),
        _ => AppColors.primary,
      };
}

class _LeadsStatusDrawer extends StatelessWidget {
  const _LeadsStatusDrawer({
    required this.stageName,
    required this.stageColor,
    required this.leads,
  });

  final String stageName;
  final Color stageColor;
  final List<Lead> leads;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: cadife.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cadife.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: stageColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    stageName,
                    style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${leads.length} leads',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: cadife.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: cadife.cardBorder),
          // Content
          Expanded(
            child: leads.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.users,
                          size: 48,
                          color: cadife.textSecondary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum lead nesta categoria',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: cadife.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: leads.length,
                    itemBuilder: (context, index) {
                      return LeadCard(lead: leads[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CadifeCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.h3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.cadife.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.cadife.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
