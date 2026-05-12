import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardMetrics {
  final int leadsQualified;
  final double conversionRate;
  final double monthlyRevenue;
  final int activeClients;

  DashboardMetrics({
    required this.leadsQualified,
    required this.conversionRate,
    required this.monthlyRevenue,
    required this.activeClients,
  });
}

class DashboardMetricsNotifier extends AsyncNotifier<DashboardMetrics> {
  @override
  Future<DashboardMetrics> build() async {
    // Simulando fetch do backend via GET /dashboard/metrics
    await Future.delayed(const Duration(milliseconds: 800));

    return DashboardMetrics(
      leadsQualified: 12,
      conversionRate: 65.0,
      monthlyRevenue: 45200.00,
      activeClients: 28,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }
}

final dashboardMetricsProvider =
    AsyncNotifierProvider<DashboardMetricsNotifier, DashboardMetrics>(
  DashboardMetricsNotifier.new,
);
