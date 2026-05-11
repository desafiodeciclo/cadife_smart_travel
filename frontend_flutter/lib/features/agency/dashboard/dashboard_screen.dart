import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/dashboard/widgets/notifications_modal.dart';
import 'package:cadife_smart_travel/providers/dashboard_provider.dart';
import 'package:cadife_smart_travel/providers/notifications_provider.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/error_state/app_error_state.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/error_state/error_type.dart';
import 'package:cadife_smart_travel/widgets/notification_badge.dart';
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
      loading: () => const LoadingShimmer(),
      error: (e, st) => AppErrorState(
        type: ErrorType.genericError,
        customSubtitle: e.toString(),
        onRetry: () => ref.read(dashboardMetricsProvider.notifier).refresh(),
      ),
    );
  }

  Widget _buildMetrics(BuildContext context, DashboardMetrics metrics, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final unreadCount = notificationsAsync.maybeWhen(
      data: (list) => list.where((n) => !n.isRead).length,
      orElse: () => 0,
    );

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(dashboardMetricsProvider),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: CadifeAppBar(
              title: 'Dashboard',
              actions: [
                NotificationBadge(
                  unreadCount: unreadCount,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const NotificationsModal(),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
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
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }
}

class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
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
