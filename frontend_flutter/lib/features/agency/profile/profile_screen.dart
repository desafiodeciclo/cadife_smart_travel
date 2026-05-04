import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/profile/consultor_profile_models.dart';
import 'package:cadife_smart_travel/features/agency/profile/profile_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ConsultorProfileScreen extends ConsumerWidget {
  const ConsultorProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(consultorProfileProvider);
    final goalsAsync = ref.watch(saleGoalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configurações',
            onPressed: () => context.push('/agency/settings'),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Erro ao carregar perfil',
                  style: AppTextStyles.bodyMedium),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.invalidate(consultorProfileProvider),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (profile) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(consultorProfileProvider);
            ref.invalidate(saleGoalsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileHeader(profile: profile),
                const SizedBox(height: 28),
                _StatsRow(profile: profile),
                const SizedBox(height: 28),
                _BioSection(profile: profile),
                const SizedBox(height: 28),
                Text('Metas Mensais', style: AppTextStyles.h4),
                const SizedBox(height: 12),
                goalsAsync.when(
                  loading: () => const _GoalsSkeleton(),
                  error: (e, _) => const SizedBox.shrink(),
                  data: (goals) => _GoalsList(goals: goals),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});
  final ConsultorProfile profile;

  @override
  Widget build(BuildContext context) {
    final initials = profile.name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          backgroundImage: profile.avatarUrl != null
              ? NetworkImage(profile.avatarUrl!)
              : null,
          child: profile.avatarUrl == null
              ? Text(
                  initials,
                  style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(profile.name, style: AppTextStyles.h4),
              const SizedBox(height: 2),
              Text(profile.email,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
              if (profile.phone != null) ...[
                const SizedBox(height: 2),
                Text(profile.phone!,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Stats ─────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.profile});
  final ConsultorProfile profile;

  @override
  Widget build(BuildContext context) {
    final pct =
        '${(profile.conversionRate * 100).toStringAsFixed(0)}%';
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.handshake_outlined,
            value: profile.totalSales.toString(),
            label: 'Vendas',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.trending_up_rounded,
            value: pct,
            label: 'Conversão',
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.calendar_month_outlined,
            value: profile.activeMonths.toString(),
            label: 'Meses ativos',
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: AppTextStyles.h4.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Bio Section ───────────────────────────────────────────────────────────────

class _BioSection extends ConsumerStatefulWidget {
  const _BioSection({required this.profile});
  final ConsultorProfile profile;

  @override
  ConsumerState<_BioSection> createState() => _BioSectionState();
}

class _BioSectionState extends ConsumerState<_BioSection> {
  bool _editing = false;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.profile.bio);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref
        .read(consultorProfileProvider.notifier)
        .updateBio(_controller.text.trim());
    if (mounted) setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Minha Bio', style: AppTextStyles.h4),
            if (!_editing)
              GestureDetector(
                onTap: () => setState(() => _editing = true),
                child: Text(
                  'Editar',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_editing)
          Column(
            children: [
              TextField(
                controller: _controller,
                maxLines: 4,
                maxLength: 300,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      _controller.text = widget.profile.bio;
                      setState(() => _editing = false);
                    },
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Salvar'),
                  ),
                ],
              ),
            ],
          )
        else
          Text(
            widget.profile.bio.isEmpty
                ? 'Adicione uma bio para se apresentar aos clientes.'
                : widget.profile.bio,
            style: AppTextStyles.bodyMedium.copyWith(
              color: widget.profile.bio.isEmpty
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
              height: 1.5,
            ),
          ),
      ],
    );
  }
}

// ── Goals List ────────────────────────────────────────────────────────────────

class _GoalsList extends StatelessWidget {
  const _GoalsList({required this.goals});
  final List<SaleGoal> goals;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return Text('Nenhuma meta registrada.',
          style:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary));
    }
    return Column(
      children: goals
          .map((g) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _GoalItem(goal: g),
              ))
          .toList(),
    );
  }
}

class _GoalItem extends StatelessWidget {
  const _GoalItem({required this.goal});
  final SaleGoal goal;

  @override
  Widget build(BuildContext context) {
    final monthLabel =
        DateFormat('MMMM yyyy', 'pt_BR').format(DateTime(goal.year, goal.month));
    final color = goal.isCompleted ? AppColors.success : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthLabel[0].toUpperCase() + monthLabel.substring(1),
                style: AppTextStyles.labelLarge,
              ),
              Row(
                children: [
                  Text(
                    '${goal.achieved}/${goal.target}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (goal.isCompleted) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.check_circle,
                        size: 16, color: AppColors.success),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goal.progressPct,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _GoalsSkeleton extends StatelessWidget {
  const _GoalsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
