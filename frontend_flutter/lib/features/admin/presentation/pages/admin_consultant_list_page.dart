import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/admin/domain/entities/admin_entities.dart';
import 'package:cadife_smart_travel/features/admin/presentation/providers/admin_providers.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/empty_state/empty_type.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/state_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ─── File-private providers para estado de filtro local da tela ──────────────

final _consultorSearchProvider = StateProvider<String>((ref) => '');
final _consultorStatusFilterProvider = StateProvider<bool?>((ref) => null);

final _filteredConsultoresProvider = Provider<AsyncValue<List<ConsultorAdmin>>>((ref) {
  final consultoresAsync = ref.watch(adminConsultoresNotifierProvider);
  final query = ref.watch(_consultorSearchProvider).toLowerCase().trim();
  final statusFilter = ref.watch(_consultorStatusFilterProvider);

  return consultoresAsync.whenData((consultores) => consultores.where((c) {
        if (statusFilter != null && c.isActive != statusFilter) return false;
        if (query.isNotEmpty) {
          return c.name.toLowerCase().contains(query) ||
              c.email.toLowerCase().contains(query) ||
              c.phone.contains(query);
        }
        return true;
      }).toList());
});

// ─── Page ────────────────────────────────────────────────────────────────────

class AdminConsultantListPage extends ConsumerStatefulWidget {
  const AdminConsultantListPage({super.key});

  @override
  ConsumerState<AdminConsultantListPage> createState() => _AdminConsultantListPageState();
}

class _AdminConsultantListPageState extends ConsumerState<AdminConsultantListPage> {
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
    ref.read(_consultorSearchProvider.notifier).state = '';
    ref.read(_consultorStatusFilterProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(_filteredConsultoresProvider);
    final totalAsync = ref.watch(adminConsultoresNotifierProvider);
    final activeStatusFilter = ref.watch(_consultorStatusFilterProvider);

    final totalCount = totalAsync.valueOrNull?.length ?? 0;
    final filteredCount = filteredAsync.valueOrNull?.length ?? 0;
    final isFiltered =
        activeStatusFilter != null || ref.watch(_consultorSearchProvider).isNotEmpty;

    return PageScaffold(
      appBar: const CadifeAppBar(
        title: 'Consultores',
        showProfile: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/agency/admin/consultants/new'),
        backgroundColor: AppColors.primary,
        child: const Icon(LucideIcons.plus, color: Colors.white, size: 24),
      ),
      body: Column(
        children: [
          _SearchBar(
            controller: _searchController,
            onChanged: (v) => ref.read(_consultorSearchProvider.notifier).state = v,
            onClear: _clearFilters,
            onFilterPressed: () => _showFilterSheet(context, ref),
            hasActiveFilters: activeStatusFilter != null,
          ),
          _StatsRow(
            totalCount: totalCount,
            filteredCount: filteredCount,
            isFiltered: isFiltered,
            onClear: _clearFilters,
          ),
          Divider(height: 1, thickness: 1, color: context.cadife.cardBorder),
          Expanded(
            child: StateListView<ConsultorAdmin>(
              state: filteredAsync,
              itemBuilder: (consultor, _) => _ConsultorCard(consultor: consultor),
              onRetry: () => ref.read(adminConsultoresNotifierProvider.notifier).refresh(),
              emptyType: EmptyType.emptySearch,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ConsultorFilterSheet(
        activeStatus: ref.watch(_consultorStatusFilterProvider),
        onStatusChanged: (s) => ref.read(_consultorStatusFilterProvider.notifier).state = s,
        onClear: _clearFilters,
      ),
    );
  }
}

// ─── Filter sheet ─────────────────────────────────────────────────────────────

class _ConsultorFilterSheet extends StatelessWidget {
  const _ConsultorFilterSheet({
    required this.activeStatus,
    required this.onStatusChanged,
    required this.onClear,
  });

  final bool? activeStatus;
  final ValueChanged<bool?> onStatusChanged;
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
          Text('Status', style: AppTextStyles.labelLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _filterOption(context, null, 'Todos'),
              _filterOption(context, true, 'Ativos'),
              _filterOption(context, false, 'Inativos'),
            ],
          ),
          const SizedBox(height: 32),
          ShadButton(
            onPressed: () => context.pop(),
            width: double.infinity,
            child: const Text(
              'Aplicar Filtros',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterOption(BuildContext context, bool? value, String label) {
    final isActive = activeStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isActive,
      onSelected: (val) {
        if (val) onStatusChanged(value);
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isActive ? AppColors.primary : context.cadife.textSecondary,
        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

// ─── Search bar ───────────────────────────────────────────────────────────────

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
        placeholder: const Text('Buscar por nome, e-mail ou telefone...'),
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

// ─── Stats row ────────────────────────────────────────────────────────────────

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
        ? '$filteredCount de $totalCount consultores'
        : '$totalCount consultores';

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

// ─── Consultor Card ───────────────────────────────────────────────────────────

class _ConsultorCard extends ConsumerWidget {
  final ConsultorAdmin consultor;
  const _ConsultorCard({required this.consultor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final borderColor = isDark ? Colors.white10 : context.cadife.cardBorder;
    final dividerColor = isDark ? Colors.white10 : context.cadife.cardBorder;
    final statusColor = consultor.isActive ? AppColors.success : AppColors.zinc400;

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
            onTap: () => context.push('/agency/admin/consultants/${consultor.id}'),
            onLongPress: () => _showOptionsModal(context, ref),
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
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            backgroundImage: consultor.avatarUrl != null
                                ? NetworkImage(consultor.avatarUrl!)
                                : null,
                            child: consultor.avatarUrl == null
                                ? const Icon(LucideIcons.user, color: AppColors.primary, size: 18)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  consultor.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  consultor.email,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.cadife.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ShadBadge(
                            backgroundColor: statusColor.withValues(alpha: 0.12),
                            foregroundColor: statusColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: statusColor.withValues(alpha: 0.25)),
                            ),
                            child: Text(consultor.isActive ? 'Ativo' : 'Inativo'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Divider(height: 1, color: dividerColor),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(LucideIcons.phone, size: 13, color: context.cadife.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            consultor.phone,
                            style: TextStyle(fontSize: 12, color: context.cadife.textSecondary),
                          ),
                          const Spacer(),
                          _StatChip(
                            icon: LucideIcons.users,
                            label: '${consultor.leadsAtivos} ativos',
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          _StatChip(
                            icon: LucideIcons.trendingUp,
                            label: '${(consultor.taxaConversao * 100).toStringAsFixed(0)}%',
                            color: AppColors.success,
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

  void _showOptionsModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cadife.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(LucideIcons.eye, color: AppColors.primary),
                title: const Text('Ver Detalhes'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/agency/admin/consultants/${consultor.id}');
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.pencil, color: AppColors.primary),
                title: const Text('Editar Consultor'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/agency/admin/consultants/${consultor.id}/edit');
                },
              ),
              ListTile(
                leading: Icon(
                  consultor.isActive ? LucideIcons.userX : LucideIcons.userCheck,
                  color: consultor.isActive ? AppColors.warning : AppColors.success,
                ),
                title: Text(consultor.isActive ? 'Desativar Consultor' : 'Ativar Consultor'),
                onTap: () {
                  Navigator.of(context).pop();
                  ref.read(adminConsultoresNotifierProvider.notifier).toggleStatus(consultor.id);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.trash2, color: AppColors.error),
                title: const Text(
                  'Excluir Consultor',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _confirmDelete(context, ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: const Text('Excluir Consultor'),
        description: Text(
          'Tem certeza que deseja excluir ${consultor.name}? Esta ação não pode ser desfeita.',
        ),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ShadButton.destructive(
            onPressed: () async {
              await ref
                  .read(adminConsultoresNotifierProvider.notifier)
                  .deleteConsultor(consultor.id);
              if (context.mounted) {
                Navigator.of(context).pop();
                ShadToaster.of(context).show(
                  const ShadToast(description: Text('Consultor excluído com sucesso!')),
                );
              }
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Chip ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
