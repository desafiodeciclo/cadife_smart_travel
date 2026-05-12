import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/admin/presentation/providers/admin_providers.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Usuário não encontrado')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'MEU PERFIL',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.settings),
                tooltip: 'Configurações',
                onPressed: () => context.push('/agency/settings'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar grande
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 3,
                    ),
                    image: user.avatarUrl != null
                        ? DecorationImage(
                            image: NetworkImage(user.avatarUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: user.avatarUrl == null
                      ? const Center(
                          child: Icon(Icons.person, size: 50, color: Colors.grey),
                        )
                      : null,
                ),

                const SizedBox(height: 16),

                // Nome
                Text(
                  user.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 4),

                // Cargo/Role
                Text(
                  user.role.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: context.cadife.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 24),

                // Seção de Métricas (centralizada)
                Text(
                  user.role == UserRole.admin
                      ? 'DESEMPENHO DA AGÊNCIA'
                      : 'SEU DESEMPENHO',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 16),

                // Grid de métricas
                if (user.role == UserRole.admin)
                  const _AgencyMetricsGrid()
                else
                  _ConsultantMetricsGrid(user: user),

                const SizedBox(height: 32),

                // Bio
                if (user.role != UserRole.admin) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'SOBRE VOCÊ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CadifeCard(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      user.bio ?? 'Nenhuma bio preenchida',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: context.cadife.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => const Scaffold(
        body: Center(child: Text('Erro ao carregar perfil')),
      ),
    );
  }
}

class _ConsultantMetricsGrid extends StatelessWidget {
  final AuthUser user;

  const _ConsultantMetricsGrid({required this.user});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        MetricCard(
          label: 'Leads Ativos',
          value: user.activeLeads.toString(),
          unit: 'leads',
          color: AppColors.primary,
          icon: Icons.trending_up,
        ),
        MetricCard(
          label: 'Taxa de Sucesso',
          value: user.successRate.toStringAsFixed(0),
          unit: '%',
          color: AppColors.success,
          icon: Icons.check_circle,
        ),
        MetricCard(
          label: 'Receita Total',
          value: 'R\$ ${(user.totalRevenue / 1000).toStringAsFixed(1)}k',
          unit: '',
          color: AppColors.info,
          icon: Icons.attach_money,
        ),
        MetricCard(
          label: 'Viagens Fechadas',
          value: user.closedDeals.toString(),
          unit: 'viagens',
          color: AppColors.scoreMorno,
          icon: Icons.done_all,
        ),
      ],
    );
  }
}

class _AgencyMetricsGrid extends ConsumerWidget {
  const _AgencyMetricsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(adminMetricsProvider);

    return metricsAsync.when(
      data: (metrics) => GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          MetricCard(
            label: 'Leads Ativos (Total)',
            value: metrics.totalLeads.toString(),
            unit: 'leads',
            color: AppColors.primary,
            icon: Icons.group,
          ),
          MetricCard(
            label: 'Taxa de Sucesso',
            value: (metrics.taxaConversao * 100).toStringAsFixed(0),
            unit: '%',
            color: AppColors.success,
            icon: Icons.check_circle,
          ),
          MetricCard(
            label: 'Receita Total',
            value: 'R\$ ${(metrics.receitaEstimada / 1000).toStringAsFixed(1)}k',
            unit: '',
            color: AppColors.info,
            icon: Icons.attach_money,
          ),
          MetricCard(
            label: 'Viagens Fechadas',
            value: metrics.leadsFechadosMes.toString(),
            unit: 'viagens',
            color: AppColors.scoreMorno,
            icon: Icons.done_all,
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Erro: $e')),
    );
  }
}

class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  const MetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CadifeCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 16,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.cadife.textPrimary,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 10,
                    color: context.cadife.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: context.cadife.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
