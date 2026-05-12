import 'package:cadife_smart_travel/design_system/design_system.dart';
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
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
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
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 24),

                // Seção de Métricas (centralizada)
                const Text(
                  'SEU DESEMPENHO',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 16),

                // Grid de métricas 2x2
                GridView.count(
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
                ),

                const SizedBox(height: 32),

                // Bio
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

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    border: Border.all(color: AppColors.borderColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.bio ?? 'Nenhuma bio preenchida',
                    style: const TextStyle(fontSize: 13, height: 1.6),
                  ),
                ),

                const SizedBox(height: 24),

                // Botão Configurações
                ElevatedButton.icon(
                  icon: const Icon(Icons.settings),
                  label: const Text('Configurações'),
                  onPressed: () => context.push('/agency/settings'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
