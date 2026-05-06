import 'package:cadife_smart_travel/config/responsive/master_detail_layout.dart';
import 'package:cadife_smart_travel/config/responsive/responsive_breakpoints.dart';
import 'package:cadife_smart_travel/core/utils/extensions/extensions.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/providers/leads_notifier.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/widgets/lead_detail_content.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/empty_state/empty_type.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/hero_image.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/state_container.dart';
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
    final selectedLeadId = ref.watch(selectedLeadIdProvider);

    return Scaffold(
      backgroundColor: context.cadife.background,
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
      body: MasterDetailLayout(
        master: (context) => Column(
          children: [
            _SearchBar(
              controller: _searchController,
              onChanged: (v) => ref.read(_searchQueryProvider.notifier).state = v,
              onClear: _clearFilters,
            ),
            _StatsRow(
              totalCount: ref.watch(leadsNotifierProvider).valueOrNull?.length ?? 0,
              filteredCount: ref.watch(_filteredLeadsProvider).valueOrNull?.length ?? 0,
              isFiltered: ref.watch(_statusFilterProvider) != null ||
                  ref.watch(_scoreFilterProvider) != null ||
                  ref.watch(_searchQueryProvider).isNotEmpty,
              onClear: _clearFilters,
            ),
            _FilterStrip(
              activeStatus: ref.watch(_statusFilterProvider),
              activeScore: ref.watch(_scoreFilterProvider),
            ),
            Divider(height: 1, thickness: 1, color: context.cadife.cardBorder),
            Expanded(
              child: StateListView<Lead>(
                state: ref.watch(_filteredLeadsProvider),
                itemBuilder: (lead, _) {
                  final isSelected = lead.id == selectedLeadId;
                  return _LeadCard(
                    lead: lead,
                    isSelected: isSelected,
                    onTap: () {
                      ref.read(selectedLeadIdProvider.notifier).state = lead.id;
                      if (context.isMobile) {
                        context.push('/agency/leads/${lead.id}');
                      }
                    },
                  );
                },
                onRetry: () => ref.read(leadsNotifierProvider.notifier).refresh(),
                emptyType: (ref.watch(_statusFilterProvider) != null ||
                        ref.watch(_scoreFilterProvider) != null ||
                        ref.watch(_searchQueryProvider).isNotEmpty)
                    ? EmptyType.emptySearch
                    : EmptyType.noLeads,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              ),
            ),
          ],
        ),
        detail: (context) => selectedLeadId != null
            ? LeadDetailContent(leadId: selectedLeadId, showAppBar: false)
            : const SizedBox.shrink(),
        showDetail: selectedLeadId != null,
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
    final isDark = context.isDark;
    return Container(
      color: context.cadife.background,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: ShadInput(
        controller: controller,
        placeholder: const Text('Buscar por nome, telefone ou destino...'),
        leading: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Icon(
            Icons.search, 
            color: isDark ? Colors.white60 : context.cadife.textSecondary, 
            size: 20
          ),
        ),
        trailing: controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.close, 
                  color: isDark ? Colors.white60 : context.cadife.textSecondary, 
                  size: 18
                ),
                onPressed: onClear,
              )
            : null,
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
            style: TextStyle(
              color: context.cadife.textSecondary,
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
      (null, 'Todos', Icons.filter_list, context.cadife.textSecondary),
      (LeadScore.quente, 'Quente', Icons.local_fire_department, AppColors.scoreQuente),
      (LeadScore.morno, 'Morno', Icons.thermostat, AppColors.scoreMorno),
      (LeadScore.frio, 'Frio', Icons.ac_unit, AppColors.scoreFrio),
    ];

    return Container(
      color: context.cadife.background,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: SizedBox(
                  height: 22,
                  child: VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: context.cadife.cardBorder,
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
    if (isActive) {
      return ShadButton(
        onPressed: onTap,
        size: ShadButtonSize.sm,
        backgroundColor: activeColor.withValues(alpha: 0.12),
        foregroundColor: activeColor,
        decoration: ShadDecoration(
          border: ShadBorder.all(
            color: activeColor,
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        leading: icon != null ? Icon(icon, size: 13) : null,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    
    return ShadButton.outline(
      onPressed: onTap,
      size: ShadButtonSize.sm,
      backgroundColor: Colors.transparent,
      foregroundColor: context.cadife.textSecondary,
      decoration: ShadDecoration(
        border: ShadBorder.all(
          color: context.cadife.cardBorder,
          width: 1,
          radius: BorderRadius.circular(20),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      leading: icon != null ? Icon(icon, size: 13) : null,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─── Lead Card ────────────────────────────────────────────────────────────────────────────────

class _LeadCard extends StatelessWidget {
  const _LeadCard({
    required this.lead,
    this.isSelected = false,
    this.onTap,
  });

  final Lead lead;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final statusColor = AppColors.statusColor(lead.status.name);
    final scoreColor = AppColors.scoreColor(lead.score.name);
    final borderColor = isSelected 
        ? context.cadife.primary 
        : (isDark ? Colors.white10 : context.cadife.cardBorder);
    final dividerColor = isDark ? Colors.white10 : context.cadife.cardBorder;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ShadCard(
        padding: EdgeInsets.zero,
        backgroundColor: isSelected 
            ? context.cadife.primary.withValues(alpha: 0.05)
            : context.cadife.cardBackground,
        radius: BorderRadius.circular(12),
        border: ShadBorder.all(
          color: borderColor, 
          width: isSelected ? 2 : 1,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
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
                      if (lead.imageUrl != null) ...[
                        HeroImage(
                          heroTag: 'lead_image_${lead.id}',
                          imageUrl: lead.imageUrl!,
                          height: 120,
                          width: double.infinity,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lead.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
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
                          Icon(Icons.phone_outlined,
                              size: 13, color: context.cadife.textSecondary),
                          const SizedBox(width: 5),
                          Text(
                            lead.phone,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.cadife.textSecondary,
                            ),
                          ),
                          if (lead.perfil != null) ...[
                            const SizedBox(width: 10),
                            Icon(Icons.people_outline,
                                size: 13, color: context.cadife.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              lead.perfil!,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.cadife.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Divider(height: 1, color: dividerColor),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.flight_takeoff,
                              size: 13, color: context.cadife.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              lead.destino ?? 'Destino a definir',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.cadife.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (lead.dataIda != null) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.calendar_today_outlined,
                                size: 12, color: context.cadife.textSecondary),
                            const SizedBox(width: 3),
                            Text(
                              lead.dataIda!.toDateString(),
                              style: TextStyle(
                                fontSize: 11,
                                color: context.cadife.textSecondary,
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
                                backgroundColor: context.cadife.cardBorder,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  lead.completudePct >= 80
                                      ? AppColors.success
                                      : lead.completudePct >= 50
                                          ? AppColors.warning
                                          : context.cadife.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${lead.completudePct}%',
                            style: TextStyle(
                              fontSize: 11,
                              color: context.cadife.textSecondary,
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
    return ShadBadge(
      backgroundColor: color.withValues(alpha: 0.10),
      foregroundColor: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(status.name.sentenceCase),
    );
  }
}

// ─── Estados auxiliares removidos (substituídos por biblioteca global) ───
