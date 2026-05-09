
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/dashboard/dashboard_provider.dart';
import 'package:cadife_smart_travel/features/agency/dashboard/widgets/funnel_section.dart';
import 'package:cadife_smart_travel/features/agency/dashboard/widgets/notification_card.dart';
import 'package:cadife_smart_travel/features/agency/dashboard/widgets/performance_section.dart';
import 'package:cadife_smart_travel/features/agency/dashboard/widgets/summary_section.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/state_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return PageScaffold(
      showProfile: false,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/agency/leads/new'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'NOVO LEAD',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: StateContainer(
        state: statsAsync,
        onRetry: () => ref.read(dashboardStatsProvider.notifier).refresh(),
        dataBuilder: (stats) {
          return RefreshIndicator(
            onRefresh: () => ref.read(dashboardStatsProvider.notifier).refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(
                  child: CadifeAppBar(
                    title: 'Dashboard',
                  ),
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

