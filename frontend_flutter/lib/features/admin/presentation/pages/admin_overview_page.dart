import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/admin/domain/entities/admin_entities.dart';
import 'package:cadife_smart_travel/features/admin/presentation/providers/admin_providers.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/state_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminOverviewPage extends ConsumerWidget {
  const AdminOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(adminMetricsProvider);

    return PageScaffold(
      appBar: const CadifeAppBar(
        title: 'Visão Geral da Agência',
        showProfile: false,
      ),
      body: StateContainer<AgenciaMetrics>(
        state: metricsAsync,
        onRetry: () => ref.refresh(adminMetricsProvider),
        dataBuilder: (metrics) {
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(adminMetricsProvider),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Métricas Globais',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.cadife.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _MetricCardGrid(metrics: metrics),
                        const SizedBox(height: 24),
                        Text(
                          'Performance do Mês',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.cadife.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _MonthlyPerformanceCard(metrics: metrics),
                        const SizedBox(height: 24),
                        Text(
                          'Ações Rápidas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.cadife.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _QuickActionsGrid(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricCardGrid extends StatelessWidget {
  final AgenciaMetrics metrics;
  const _MetricCardGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MetricItem(
        label: 'Total de Leads',
        value: metrics.totalLeads.toString(),
        icon: LucideIcons.users,
        color: AppColors.primary,
      ),
      _MetricItem(
        label: 'Taxa de Conversão',
        value: '${(metrics.taxaConversao * 100).toStringAsFixed(1)}%',
        icon: LucideIcons.trendingUp,
        color: AppColors.success,
      ),
      _MetricItem(
        label: 'Receita Estimada',
        value: 'R\$ ${(metrics.receitaEstimada / 1000000).toStringAsFixed(2)}M',
        icon: LucideIcons.banknote,
        color: AppColors.info,
      ),
      _MetricItem(
        label: 'Consultores Ativos',
        value: metrics.consultoresAtivos.toString(),
        icon: LucideIcons.userCheck,
        color: AppColors.warning,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: items.map((item) => _MetricCard(item: item)).toList(),
    );
  }
}

class _MetricItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MetricItem({required this.label, required this.value, required this.icon, required this.color});
}

class _MetricCard extends StatelessWidget {
  final _MetricItem item;
  const _MetricCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      padding: const EdgeInsets.all(16),
      radius: BorderRadius.circular(12),
      border: ShadBorder.all(color: context.cadife.cardBorder.withValues(alpha: 0.5), width: 1),
      backgroundColor: context.cadife.cardBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, size: 18, color: item.color),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 12,
                  color: context.cadife.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthlyPerformanceCard extends StatelessWidget {
  final AgenciaMetrics metrics;
  const _MonthlyPerformanceCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      padding: const EdgeInsets.all(16),
      radius: BorderRadius.circular(12),
      border: ShadBorder.all(color: context.cadife.cardBorder.withValues(alpha: 0.5), width: 1),
      backgroundColor: context.cadife.cardBackground,
      child: Column(
        children: [
          _PerformanceRow(
            label: 'Leads Novos',
            value: metrics.leadsNovosMes.toString(),
            icon: LucideIcons.userPlus,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          _PerformanceRow(
            label: 'Leads Fechados',
            value: metrics.leadsFechadosMes.toString(),
            icon: Icons.check_circle_outline,
            color: AppColors.success,
          ),
          const SizedBox(height: 12),
          _PerformanceRow(
            label: 'Leads Perdidos',
            value: metrics.leadsPerdidosMes.toString(),
            icon: Icons.cancel_outlined,
            color: AppColors.zinc500,
          ),
        ],
      ),
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _PerformanceRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: context.cadife.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _QuickActionsGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        CadifeButton(
          text: 'Gerenciar Consultores',
          icon: LucideIcons.users,
          analyticsLabel: 'admin_consultores',
          onPressed: () => context.push('/agency/admin/consultants'),
        ),
        const SizedBox(height: 12),
        CadifeButton(
          text: 'Todos os Leads',
          icon: LucideIcons.clipboardList,
          variant: ButtonVariant.secondary,
          isOutline: true,
          analyticsLabel: 'admin_all_leads',
          onPressed: () => context.push('/agency/admin/leads'),
        ),
      ],
    );
  }
}
