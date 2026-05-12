import 'package:cadife_smart_travel/core/utils/extensions/extensions.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/providers/leads_notifier.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/widgets/lead_card.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cadife_smart_travel/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/empty_state/empty_type.dart';
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

    final authAsync = ref.watch(authNotifierProvider);
    final user = authAsync.valueOrNull;
    final canCreateManual = user?.role == UserRole.admin || user?.role == UserRole.consultor;


    return PageScaffold(
      appBar: const CadifeAppBar(
        title: 'Leads',
        actions: [
          NotificationBell(),
          SizedBox(width: 8),
        ],
      ),
      floatingActionButton: canCreateManual 
        ? FloatingActionButton.extended(
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
          )
        : null,
      body: Column(
        children: [
          _SearchBar(
            controller: _searchController,
            onChanged: (v) => ref.read(_searchQueryProvider.notifier).state = v,
            onClear: _clearFilters,
            onFilterPressed: () => _showFilterOptions(context, ref),
            hasActiveFilters: activeStatus != null || activeScore != null,
          ),
          _StatsRow(
            totalCount: totalCount,
            filteredCount: filteredCount,
            isFiltered: isFiltered,
            onClear: _clearFilters,
          ),

          Divider(height: 1, thickness: 1, color: context.cadife.cardBorder),
          Expanded(
            child: StateListView<Lead>(
              state: filteredAsync,
              itemBuilder: (lead, _) => LeadCard(lead: lead),
              onRetry: () => ref.read(leadsNotifierProvider.notifier).refresh(),
              emptyType: isFiltered ? EmptyType.emptySearch : EmptyType.noLeads,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), // More padding at bottom for FAB
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
      builder: (context) => _LeadsFilterSheet(
        activeStatus: ref.watch(_statusFilterProvider),
        activeScore: ref.watch(_scoreFilterProvider),
        onStatusChanged: (s) => ref.read(_statusFilterProvider.notifier).state = s,
        onScoreChanged: (s) => ref.read(_scoreFilterProvider.notifier).state = s,
        onClear: _clearFilters,
      ),
    );
  }
}

class _LeadsFilterSheet extends StatelessWidget {
  const _LeadsFilterSheet({
    required this.activeStatus,
    required this.activeScore,
    required this.onStatusChanged,
    required this.onScoreChanged,
    required this.onClear,
  });

  final LeadStatus? activeStatus;
  final LeadScore? activeScore;
  final ValueChanged<LeadStatus?> onStatusChanged;
  final ValueChanged<LeadScore?> onScoreChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
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
                  if (val) onStatusChanged(s);
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
          Text('Score (Temperatura)', style: AppTextStyles.labelLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              null,
              ...LeadScore.values,
            ].map((s) {
              final isActive = activeScore == s;
              final label = s == null ? 'Todos' : s.name.sentenceCase;
              return ChoiceChip(
                label: Text(label),
                selected: isActive,
                onSelected: (val) {
                  if (val) onScoreChanged(s);
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

// ─── Search bar ────────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onFilterPressed,
    required this.hasActiveFilters,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilterPressed;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final cadife = context.cadife;
    return Container(
      color: cadife.background,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: ShadInput(
        controller: controller,
        placeholder: const Text('Buscar por nome, telefone ou destino...'),
        leading: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Icon(
            LucideIcons.search, 
            color: isDark ? Colors.white60 : cadife.textSecondary, 
            size: 18
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
                  size: 16
                ),
                width: 32,
                height: 32,
                padding: EdgeInsets.zero,
                onPressed: onClear,
              ),
              const SizedBox(width: 4),
            ],
            Container(
              width: 1,
              height: 20,
              color: cadife.cardBorder,
            ),
            const SizedBox(width: 4),
            ShadIconButton.ghost(
              icon: Icon(
                LucideIcons.slidersHorizontal, 
                color: hasActiveFilters ? AppColors.primary : (isDark ? Colors.white60 : cadife.textSecondary),
                size: 18
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



// ─── Lead Card ────────────────────────────────────────────────────────────────────────────────



// ─── Estados auxiliares removidos (substituídos por biblioteca global) ───
