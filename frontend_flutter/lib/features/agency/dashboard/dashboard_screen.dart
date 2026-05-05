
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/dashboard/dashboard_provider.dart';
import 'package:cadife_smart_travel/features/agency/dashboard/widgets/funnel_section.dart';
import 'package:cadife_smart_travel/features/agency/dashboard/widgets/notification_card.dart';
import 'package:cadife_smart_travel/features/agency/dashboard/widgets/performance_section.dart';
import 'package:cadife_smart_travel/features/agency/dashboard/widgets/summary_section.dart';
import 'package:cadife_smart_travel/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/state_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      body: StateContainer(
        state: statsAsync,
        onRetry: () => ref.read(dashboardStatsProvider.notifier).refresh(),
        dataBuilder: (stats) {
          return RefreshIndicator(
            onRefresh: () => ref.read(dashboardStatsProvider.notifier).refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const CadifeAppBar(
                  title: 'Dashboard',
                  showNotificationBell: false,
                  actions: [NotificationBell()],
                ),
                SliverToBoxAdapter(
                  child: NotificationCard(
                    leadName: 'Mariana S.',
                    timeAgo: 'Há 2 min',
                    onClose: () {},
                    onTap: () => context.push('/agency/leads'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SummarySection(stats: stats),
                ),
                SliverToBoxAdapter(
                  child: PerformanceSection(stats: stats),
                ),
                SliverToBoxAdapter(
                  child: FunnelSection(stats: stats),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 24),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

