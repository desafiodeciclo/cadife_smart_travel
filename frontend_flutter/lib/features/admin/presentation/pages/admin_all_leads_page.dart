import 'package:cadife_smart_travel/core/utils/extensions/extensions.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
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
        showProfile: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/agency/leads/new'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          _AdminSearchBar(
            controller: _searchController,
            onChanged: (v) => ref.read(_adminSearchQueryProvider.notifier).state = v,
            onClear: _clearFilters,
            onFilterPressed: () => _showFilterOptions(context, ref),
            hasActiveFilters: activeStatus != null || activeConsultor != null,
          ),
          _AdminStatsRow(
            totalCount: totalCount,
            filteredCount: filteredCount,
            isFiltered: isFiltered,
            onClear: _clearFilters,
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
  void _showFilterOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AdminFilterSheet(
        activeStatus: ref.watch(_adminStatusFilterProvider),
        activeConsultor: ref.watch(_adminConsultorFilterProvider),
        onClear: _clearFilters,
      ),
    );
  }
}

class _AdminFilterSheet extends ConsumerWidget {
  const _AdminFilterSheet({
    required this.activeStatus,
    required this.activeConsultor,
    required this.onClear,
  });

  final LeadStatus? activeStatus;
  final String? activeConsultor;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cadife = context.cadife;
    final consultoresAsync = ref.watch(adminConsultoresProvider);

    return Container(
      decoration: BoxDecoration(
        color: cadife.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cadife.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filtros', style: AppTextStyles.h4),
              TextButton(
                onPressed: () {
                  onClear();
                  context.pop();
                },
                child: const Text('Limpar'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Status do Lead', style: AppTextStyles.labelLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              null,
              ...LeadStatus.values,
            ].map((s) {
              final isActive = activeStatus == s;
              final label = s == null ? 'Todos' : s.name.sentenceCase;
              return ChoiceChip(
                label: Text(label),
                selected: isActive,
                onSelected: (val) {
                  if (val) ref.read(_adminStatusFilterProvider.notifier).state = s;
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isActive ? AppColors.primary : cadife.textSecondary,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text('Consultor', style: AppTextStyles.labelLarge),
          const SizedBox(height: 12),
          consultoresAsync.when(
            data: (consultores) {
              final allConsultores = [null, ...consultores];
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allConsultores.map((c) {
                  final label = c?.name ?? 'Todos';
                  final value = c?.name;
                  final isActive = activeConsultor == value;
                  return ChoiceChip(
                    label: Text(label),
                    selected: isActive,
                    onSelected: (val) {
                      if (val) ref.read(_adminConsultorFilterProvider.notifier).state = value;
                    },
                    selectedColor: AppColors.info.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.info,
                    labelStyle: TextStyle(
                      color: isActive ? AppColors.info : cadife.textSecondary,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Text('Erro ao carregar consultores'),
          ),
          const SizedBox(height: 32),
          ShadButton(
            onPressed: () => context.pop(),
            width: double.infinity,
            child: const Text('Aplicar Filtros'),
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
  final VoidCallback onFilterPressed;
  final bool hasActiveFilters;

  const _AdminSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onFilterPressed,
    required this.hasActiveFilters,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final cadife = context.cadife;
    return Container(
      color: cadife.background,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: ShadInput(
        controller: controller,
        placeholder: const Text('Buscar por nome, telefone, destino ou consultor...'),
        leading: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Icon(
            LucideIcons.search,
            color: isDark ? Colors.white60 : cadife.textSecondary,
            size: 18,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controller.text.isNotEmpty) ...[
              ShadIconButton.ghost(
                icon: Icon(
                  LucideIcons.x,
                  color: isDark ? Colors.white60 : cadife.textSecondary,
                  size: 16,
                ),
                width: 32,
                height: 32,
                padding: EdgeInsets.zero,
                onPressed: onClear,
              ),
              const SizedBox(width: 4),
            ],
            Container(width: 1, height: 20, color: cadife.cardBorder),
            const SizedBox(width: 4),
            ShadIconButton.ghost(
              icon: Icon(
                LucideIcons.slidersHorizontal,
                color: hasActiveFilters
                    ? AppColors.primary
                    : (isDark ? Colors.white60 : cadife.textSecondary),
                size: 18,
              ),
              width: 32,
              height: 32,
              padding: EdgeInsets.zero,
              onPressed: onFilterPressed,
            ),
            const SizedBox(width: 4),
          ],
        ),
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
