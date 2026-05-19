import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:cadife_smart_travel/features/agency/perfil/domain/repositories/i_consultor_repository.dart';
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
    final result = await sl<IConsultorRepository>().getMetrics();
    return result.fold(
      (failure) => throw failure,
      (m) => DashboardMetrics(
        leadsQualified: m.totalLeadsAtendidos,
        conversionRate: m.taxaConversao * 100,
        monthlyRevenue: m.receitaGerada,
        activeClients: m.leadsAtivosAgora,
      ),
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
