import 'package:cadife_smart_travel/core/utils/extensions/extensions.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/admin/domain/entities/admin_entities.dart';
import 'package:cadife_smart_travel/features/admin/presentation/providers/admin_providers.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/providers/leads_notifier.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/empty_state/app_empty_state.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/empty_state/empty_type.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/error_state/app_error_state.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/error_state/error_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _adminSearchQueryProvider = StateProvider<String>((ref) => '');
final _adminStatusFilterProvider = StateProvider<LeadStatus?>((ref) => null);
final _adminConsultorFilterProvider = StateProvider<String?>((ref) => null);

final _adminAllLeadsProvider = Provider<AsyncValue<List<Lead>>>((ref) {
  final leadsAsync = ref.watch(leadsNotifierProvider);
  final query = ref.watch(_adminSearchQueryProvider).toLowerCase().trim();
  final status = ref.watch(_adminStatusFilterProvider);
  final consultorId = ref.watch(_adminConsultorFilterProvider);

  return leadsAsync.whenData((leads) => leads.where((l) {
    if (status != null && l.status != status) return false;
    if (consultorId != null && l.assignedTo != consultorId && l.consultorNome != consultorId) return false;
    if (query.isNotEmpty) {
      return l.name.toLowerCase().contains(query) ||
          l.phone.contains(query) ||
          (l.destino?.toLowerCase().contains(query) ?? false) ||
          (l.consultorNome?.toLowerCase().contains(query) ?? false);
    }
    return true;
  }).toList());
});

class AdminAllLeadsPage extends ConsumerStatefulWidget {
  const AdminAllLeadsPage({super.key});

  @override
  ConsumerState<AdminAllLeadsPage> createState() => _AdminAllLeadsPageState();
}

class _AdminAllLeadsPageState extends ConsumerState<AdminAllLeadsPage> {
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
    ref.read(_adminSearchQueryProvider.notifier).state = '';
    ref.read(_adminStatusFilterProvider.notifier).state = null;
    ref.read(_adminConsultorFilterProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(_adminAllLeadsProvider);
    final totalAsync = ref.watch(leadsNotifierProvider);
    final activeStatus = ref.watch(_adminStatusFilterProvider);
    final activeConsultor = ref.watch(_adminConsultorFilterProvider);

    final totalCount = totalAsync.valueOrNull?.length ?? 0;
    final filteredCount = filteredAsync.valueOrNull?.length ?? 0;
    final isFiltered = activeStatus != null ||
        activeConsultor != null ||
        ref.watch(_adminSearchQueryProvider).isNotEmpty;

    return PageScaffold(
      appBar: const CadifeAppBar(
        title: 'Todos os Leads',
        showProfile: false,
      ),
      body: Column(
        children: [
          _AdminSearchBar(
            controller: _searchController,
            onChanged: (v) => ref.read(_adminSearchQueryProvider.notifier).state = v,
            onClear: _clearFilters,
          ),
          _AdminStatsRow(
            totalCount: totalCount,
            filteredCount: filteredCount,
            isFiltered: isFiltered,
            onClear: _clearFilters,
          ),
          _AdminFilterStrip(
            activeStatus: activeStatus,
            activeConsultor: activeConsultor,
          ),
          Divider(height: 1, thickness: 1, color: context.cadife.cardBorder),
          Expanded(
            child: filteredAsync.when(
              data: (leads) {
                if (leads.isEmpty) {
                  return AppEmptyState(
                    type: isFiltered ? EmptyType.emptySearch : EmptyType.noLeads,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.read(leadsNotifierProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: leads.length,
                    itemBuilder: (context, index) => _AdminLeadCard(lead: leads[index]),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => AppErrorState(
                type: ErrorType.genericError,
                onRetry: () => ref.read(leadsNotifierProvider.notifier).refresh(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _AdminSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      color: context.cadife.background,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: ShadInput(
        controller: controller,
        placeholder: const Text('Buscar por nome, telefone, destino ou consultor...'),
        leading: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Icon(
            Icons.search,
            color: isDark ? Colors.white60 : context.cadife.textSecondary,
            size: 20,
          ),
        ),
        trailing: controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.close,
                  color: isDark ? Colors.white60 : context.cadife.textSecondary,
                  size: 18,
                ),
                onPressed: onClear,
              )
            : null,
        onChanged: onChanged,
      ),
    );
  }
}

class _AdminStatsRow extends StatelessWidget {
  final int totalCount;
  final int filteredCount;
  final bool isFiltered;
  final VoidCallback onClear;

  const _AdminStatsRow({
    required this.totalCount,
    required this.filteredCount,
    required this.isFiltered,
    required this.onClear,
  });

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

class _AdminFilterStrip extends ConsumerWidget {
  final LeadStatus? activeStatus;
  final String? activeConsultor;

  const _AdminFilterStrip({
    required this.activeStatus,
    required this.activeConsultor,
  });

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
    final consultoresAsync = ref.watch(adminConsultoresProvider);

    return Container(
      color: context.cadife.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 40, 6),
            child: Row(
              children: [
                ..._statuses.map((s) {
                  final isActive = activeStatus == s;
                  final color = s == null ? AppColors.primary : AppColors.statusColor(s.name);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _AdminFilterChip(
                      label: _statusLabel(s),
                      isActive: isActive,
                      activeColor: color,
                      onTap: () => ref.read(_adminStatusFilterProvider.notifier).state = s,
                    ),
                  );
                }),
              ],
            ),
          ),
          // Consultant filter chips
          consultoresAsync.when(
            data: (consultores) {
              if (consultores.isEmpty) return const SizedBox.shrink();
              final List<ConsultorAdmin?> allConsultores = [null, ...consultores];
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 40, 10),
                child: Row(
                  children: [
                    ...allConsultores.map((c) {
                      final label = c?.name ?? 'Todos';
                      final value = c?.name;
                      final isActive = activeConsultor == value;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _AdminFilterChip(
                          label: label,
                          isActive: isActive,
                          activeColor: AppColors.info,
                          onTap: () => ref.read(_adminConsultorFilterProvider.notifier).state = value,
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _AdminFilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _AdminFilterChip({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isActive) {
      return ShadButton(
        onPressed: onTap,
        size: ShadButtonSize.sm,
        backgroundColor: activeColor.withValues(alpha: 0.12),
        foregroundColor: activeColor,
        decoration: ShadDecoration(
          border: ShadBorder.all(color: activeColor, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _AdminLeadCard extends StatelessWidget {
  final Lead lead;
  const _AdminLeadCard({required this.lead});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.statusColor(lead.status.name);
    final borderColor = context.isDark ? Colors.white10 : context.cadife.cardBorder;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ShadCard(
        padding: EdgeInsets.zero,
        backgroundColor: context.cadife.cardBackground,
        radius: BorderRadius.circular(12),
        border: ShadBorder.all(color: borderColor, width: 1),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/agency/leads/${lead.id}'),
            child: Stack(
              children: [
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
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ShadBadge(
                            backgroundColor: statusColor.withValues(alpha: 0.10),
                            foregroundColor: statusColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: statusColor.withValues(alpha: 0.25)),
                            ),
                            child: Text(lead.status.name.sentenceCase),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined, size: 13, color: context.cadife.textSecondary),
                          const SizedBox(width: 5),
                          Text(
                            lead.phone,
                            style: TextStyle(fontSize: 12, color: context.cadife.textSecondary),
                          ),
                          if (lead.destino != null) ...[
                            const SizedBox(width: 10),
                            Icon(Icons.flight_takeoff, size: 13, color: context.cadife.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                lead.destino!,
                                style: TextStyle(fontSize: 12, color: context.cadife.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Divider(height: 1, color: borderColor),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(LucideIcons.user, size: 13, color: context.cadife.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            lead.consultorNome ?? 'Sem consultor',
                            style: TextStyle(
                              fontSize: 12,
                              color: lead.consultorNome != null
                                  ? context.cadife.textPrimary
                                  : context.cadife.textSecondary,
                              fontWeight: lead.consultorNome != null
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                lead.score == LeadScore.quente
                                    ? Icons.local_fire_department
                                    : lead.score == LeadScore.morno
                                        ? Icons.thermostat
                                        : Icons.ac_unit,
                                size: 13,
                                color: AppColors.scoreColor(lead.score.name),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                lead.score.name.capitalized,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.scoreColor(lead.score.name),
                                ),
                              ),
                            ],
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
}
