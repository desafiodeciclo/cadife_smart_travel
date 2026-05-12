import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/admin/presentation/providers/admin_consultants_provider.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/empty_state/empty_type.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/state_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminConsultantManagementPage extends ConsumerStatefulWidget {
  const AdminConsultantManagementPage({super.key});

  @override
  ConsumerState<AdminConsultantManagementPage> createState() => _AdminConsultantManagementPageState();
}

class _AdminConsultantManagementPageState extends ConsumerState<AdminConsultantManagementPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminConsultantsNotifierProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateModal() {
    showShadDialog(
      context: context,
      builder: (context) => const _CreateConsultantDialog(),
    );
  }

  void _showDeleteDialog(AdminConsultant consultant) {
    showShadDialog(
      context: context,
      builder: (context) => _DeleteConsultantDialog(consultant: consultant),
    );
  }

  @override
  Widget build(BuildContext context) {
    final consultantsAsync = ref.watch(adminConsultantsNotifierProvider);
    final query = _searchController.text.toLowerCase().trim();

    final filteredAsync = consultantsAsync.whenData((list) {
      if (query.isEmpty) return list;
      return list.where((c) {
        return c.name.toLowerCase().contains(query) ||
            c.email.toLowerCase().contains(query) ||
            (c.phone?.contains(query) ?? false);
      }).toList();
    });

    return PageScaffold(
      appBar: CadifeAppBar(
        title: 'Gestão de Consultores',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: _showCreateModal,
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            onClear: () {
              _searchController.clear();
              setState(() {});
            },
          ),
          Expanded(
            child: StateListView<AdminConsultant>(
              state: filteredAsync,
              itemBuilder: (consultant, _) => _ConsultantCard(
                consultant: consultant,
                onToggleStatus: (isActive) async {
                  await ref
                      .read(adminConsultantsNotifierProvider.notifier)
                      .updateConsultant(consultant.id, isActive: isActive);
                },
                onDelete: () => _showDeleteDialog(consultant),
              ),
              onRetry: () => ref.read(adminConsultantsNotifierProvider.notifier).refresh(),
              emptyType: EmptyType.emptyList,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            ),
          ),
        ],
      ),
    );
  }
}

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
        placeholder: const Text('Buscar por nome, e-mail ou telefone...'),
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

class _ConsultantCard extends StatelessWidget {
  const _ConsultantCard({
    required this.consultant,
    required this.onToggleStatus,
    required this.onDelete,
  });

  final AdminConsultant consultant;
  final ValueChanged<bool> onToggleStatus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final borderColor = isDark ? Colors.white10 : context.cadife.cardBorder;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ShadCard(
        padding: const EdgeInsets.all(16),
        backgroundColor: context.cadife.cardBackground,
        radius: BorderRadius.circular(12),
        border: ShadBorder.all(color: borderColor, width: 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    consultant.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StatusBadge(isActive: consultant.isActive),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.email_outlined, size: 13, color: context.cadife.textSecondary),
                const SizedBox(width: 5),
                Text(
                  consultant.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.cadife.textSecondary,
                  ),
                ),
              ],
            ),
            if (consultant.phone != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 13, color: context.cadife.textSecondary),
                  const SizedBox(width: 5),
                  Text(
                    consultant.phone!,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.cadife.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Divider(height: 1, color: borderColor),
            const SizedBox(height: 12),
            Row(
              children: [
                _MetricItem(
                  label: 'Total Leads',
                  value: consultant.metrics.totalLeads.toString(),
                  icon: Icons.people_outline,
                ),
                const SizedBox(width: 16),
                _MetricItem(
                  label: 'Ativos',
                  value: consultant.metrics.activeLeads.toString(),
                  icon: Icons.trending_up,
                ),
                const SizedBox(width: 16),
                _MetricItem(
                  label: 'Fechados',
                  value: consultant.metrics.closedLeads.toString(),
                  icon: Icons.check_circle_outline,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ShadButton.outline(
                    onPressed: () => onToggleStatus(!consultant.isActive),
                    size: ShadButtonSize.sm,
                    child: Text(consultant.isActive ? 'Desativar' : 'Ativar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ShadButton.destructive(
                    onPressed: onDelete,
                    size: ShadButtonSize.sm,
                    child: const Text('Excluir'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: context.cadife.textSecondary),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: context.cadife.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : context.cadife.textSecondary;
    return ShadBadge(
      backgroundColor: color.withValues(alpha: 0.10),
      foregroundColor: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(isActive ? 'Ativo' : 'Inativo'),
    );
  }
}

class _CreateConsultantDialog extends ConsumerStatefulWidget {
  const _CreateConsultantDialog();

  @override
  ConsumerState<_CreateConsultantDialog> createState() => _CreateConsultantDialogState();
}

class _CreateConsultantDialogState extends ConsumerState<_CreateConsultantDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  UserRole _selectedRole = UserRole.consultor;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty) {
      return;
    }
    setState(() => _isLoading = true);
    await ref.read(adminConsultantsNotifierProvider.notifier).createConsultant(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          role: _selectedRole,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      title: const Text('Novo Consultor'),
      description: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Crie um novo perfil de consultor. Uma senha temporária será enviada por e-mail.'),
          const SizedBox(height: 12),
          ShadInput(
            controller: _nameController,
            placeholder: const Text('Nome completo'),
          ),
          const SizedBox(height: 8),
          ShadInput(
            controller: _emailController,
            placeholder: const Text('E-mail'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 8),
          ShadInput(
            controller: _phoneController,
            placeholder: const Text('Telefone (opcional)'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 8),
          ShadSelect<UserRole>(
            placeholder: const Text('Perfil'),
            initialValue: _selectedRole,
            options: const [
              ShadOption(value: UserRole.consultor, child: Text('Consultor')),
            ],
            selectedOptionBuilder: (context, value) => const Text('Consultor'),
            onChanged: (value) {
              if (value != null) setState(() => _selectedRole = value);
            },
          ),
        ],
      ),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ShadButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Criar'),
        ),
      ],
    );
  }
}

class _DeleteConsultantDialog extends ConsumerStatefulWidget {
  const _DeleteConsultantDialog({required this.consultant});

  final AdminConsultant consultant;

  @override
  ConsumerState<_DeleteConsultantDialog> createState() => _DeleteConsultantDialogState();
}

class _DeleteConsultantDialogState extends ConsumerState<_DeleteConsultantDialog> {
  bool _isLoading = false;

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    await ref.read(adminConsultantsNotifierProvider.notifier).deleteConsultant(widget.consultant.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      title: const Text('Confirmar exclusão'),
      description: Text(
        'Deseja desativar a conta de ${widget.consultant.name}? Os leads ativos poderão ser reatribuídos.',
      ),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ShadButton.destructive(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Desativar'),
        ),
      ],
    );
  }
}
