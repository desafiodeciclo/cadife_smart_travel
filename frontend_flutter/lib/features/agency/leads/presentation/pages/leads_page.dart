import 'package:cadife_smart_travel/core/utils/extensions/extensions.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/providers/leads_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ─── File-private providers para estado de filtro local da tela ─────────────────────────────

final _searchQueryProvider = StateProvider<String>((ref) => '');
final _statusFilterProvider = StateProvider<LeadStatus?>((ref) => null);
final _scoreFilterProvider = StateProvider<LeadScore?>((ref) => null);

final _filteredLeadsProvider = Provider<AsyncValue<List<Lead>>>((ref) {
  final leadsAsync = ref.watch(leadsNotifierProvider);
  final query = ref.watch(_searchQueryProvider).toLowerCase().trim();
  final status = ref.watch(_statusFilterProvider);
  final score = ref.watch(_scoreFilterProvider);

  return leadsAsync.whenData((leads) => leads.where((l) {
        if (status != null && l.status != status) return false;
        if (score != null && l.score != score) return false;
        if (query.isNotEmpty) {
          return l.name.toLowerCase().contains(query) ||
              l.phone.contains(query) ||
              (l.destino?.toLowerCase().contains(query) ?? false);
        }
        return true;
      }).toList());
});

// ─── Page ────────────────────────────────────────────────────────────────────────────────

class LeadsPage extends ConsumerStatefulWidget {
  const LeadsPage({super.key});

  @override
  ConsumerState<LeadsPage> createState() => _LeadsPageState();
}

class _LeadsPageState extends ConsumerState<LeadsPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _searchController.clear();
    ref.read(_searchQueryProvider.notifier).state = '';
    ref.read(_statusFilterProvider.notifier).state = null;
    ref.read(_scoreFilterProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(_filteredLeadsProvider);
    final totalAsync = ref.watch(leadsNotifierProvider);
    final activeStatus = ref.watch(_statusFilterProvider);
    final activeScore = ref.watch(_scoreFilterProvider);

    final totalCount = totalAsync.valueOrNull?.length ?? 0;
    final filteredCount = filteredAsync.valueOrNull?.length ?? 0;
    final isFiltered = activeStatus != null ||
        activeScore != null ||
        ref.watch(_searchQueryProvider).isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CadifeAppBar(
        title: 'Leads',
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Novo lead',
            onPressed: () => context.push('/agency/leads/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(
            controller: _searchController,
            onChanged: (v) => ref.read(_searchQueryProvider.notifier).state = v,
            onClear: _clearFilters,
          ),
          _StatsRow(
            totalCount: totalCount,
            filteredCount: filteredCount,
            isFiltered: isFiltered,
            onClear: _clearFilters,
          ),
          _FilterStrip(activeStatus: activeStatus, activeScore: activeScore),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          Expanded(
            child: filteredAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => _ErrorView(
                onRetry: () => ref.read(leadsNotifierProvider.notifier).refresh(),
              ),
              data: (leads) => leads.isEmpty
                  ? const _EmptyView()
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => ref.read(leadsNotifierProvider.notifier).refresh(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        itemCount: leads.length,
                        itemBuilder: (_, i) => _LeadCard(lead: leads[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search bar ────────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: TextField(
        controller: controller,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Buscar por nome, telefone ou destino...',
          hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 18),
                  onPressed: onClear,
                )
              : null,
          fillColor: AppColors.surface,
          filled: true,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

// ─── Stats row ────────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.totalCount,
    required this.filteredCount,
    required this.isFiltered,
    required this.onClear,
  });

  final int totalCount;
  final int filteredCount;
  final bool isFiltered;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final label = isFiltered
        ? '$filteredCount de $totalCount leads'
        : '$totalCount leads';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isFiltered) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onClear,
              child: const Text(
                '· Limpar filtros',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Combined filter strip (status + score em um único scroll horizontal) ──────────────────────

class _FilterStrip extends ConsumerWidget {
  const _FilterStrip({required this.activeStatus, required this.activeScore});

  final LeadStatus? activeStatus;
  final LeadScore? activeScore;

  static const _statuses = [null, ...LeadStatus.values];

  String _statusLabel(LeadStatus? s) {
    if (s == null) return 'Todos';
    return switch (s) {
      LeadStatus.novo => 'Novo',
      LeadStatus.emAtendimento => 'Em Atend.',
      LeadStatus.qualificado => 'Qualificado',
      LeadStatus.agendado => 'Agendado',
      LeadStatus.proposta => 'Proposta',
      LeadStatus.fechado => 'Fechado',
      LeadStatus.perdido => 'Perdido',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scores = <(LeadScore?, String, IconData, Color)>[
      (null, 'Todos', Icons.filter_list, AppColors.textSecondary),
      (LeadScore.quente, 'Quente', Icons.local_fire_department, AppColors.scoreQuente),
      (LeadScore.morno, 'Morno', Icons.thermostat, AppColors.scoreMorno),
      (LeadScore.frio, 'Frio', Icons.ac_unit, AppColors.scoreFrio),
    ];

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.white, Colors.white, Colors.transparent],
          stops: [0.0, 0.85, 1.0],
        ).createShader(bounds),
        blendMode: BlendMode.dstIn,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 8, 40, 10),
          child: Row(
            children: [
              // Status chips
              ..._statuses.map((s) {
                final isActive = activeStatus == s;
                final color = s == null
                    ? AppColors.primary
                    : AppColors.statusColor(s.name);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: _statusLabel(s),
                    isActive: isActive,
                    activeColor: color,
                    onTap: () =>
                        ref.read(_statusFilterProvider.notifier).state = s,
                  ),
                );
              }),
              // Separador visual entre status e score
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: SizedBox(
                  height: 22,
                  child: VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppColors.border,
                  ),
                ),
              ),
              // Score chips
              ...scores.map((entry) {
                final (score, label, icon, color) = entry;
                final isActive = activeScore == score;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: label,
                    icon: icon,
                    isActive: isActive,
                    activeColor: color,
                    onTap: () =>
                        ref.read(_scoreFilterProvider.notifier).state = score,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor : AppColors.border,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isActive ? activeColor : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Lead Card ────────────────────────────────────────────────────────────────────────────────

class _LeadCard extends StatelessWidget {
  const _LeadCard({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.statusColor(lead.status.name);
    final scoreColor = AppColors.scoreColor(lead.score.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/agency/leads/${lead.id}'),
          child: Stack(
            children: [
              // Borda lateral colorida por status
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lead.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(status: lead.status, color: statusColor),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 5),
                        Text(
                          lead.phone,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (lead.perfil != null) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.people_outline,
                              size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            lead.perfil!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.flight_takeoff,
                            size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            lead.destino ?? 'Destino a definir',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (lead.dataIda != null) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.calendar_today_outlined,
                              size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Text(
                            lead.dataIda!.toDateString(),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(width: 10),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _scoreIcon(lead.score),
                              size: 13,
                              color: scoreColor,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              lead.score.name.capitalized,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: scoreColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: lead.completudePct / 100,
                              minHeight: 4,
                              backgroundColor: AppColors.border,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                lead.completudePct >= 80
                                    ? AppColors.success
                                    : lead.completudePct >= 50
                                        ? AppColors.warning
                                        : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${lead.completudePct}%',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _scoreIcon(LeadScore score) => switch (score) {
        LeadScore.quente => Icons.local_fire_department,
        LeadScore.morno => Icons.thermostat,
        LeadScore.frio => Icons.ac_unit,
      };
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});

  final LeadStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        status.name.sentenceCase,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ─── Estados auxiliares ────────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          const Text(
            'Erro ao carregar leads',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          CadifeButton(
            onPressed: onRetry,
            text: 'Tentar novamente',
            icon: Icons.refresh,
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 56, color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          const Text(
            'Nenhum lead encontrado',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tente ajustar os filtros ou a busca',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
