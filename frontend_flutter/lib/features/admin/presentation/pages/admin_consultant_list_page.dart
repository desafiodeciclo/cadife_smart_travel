import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/admin/domain/entities/admin_entities.dart';
import 'package:cadife_smart_travel/features/admin/presentation/providers/admin_providers.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/empty_state/app_empty_state.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/empty_state/empty_type.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/error_state/app_error_state.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/error_state/error_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminConsultantListPage extends ConsumerWidget {
  const AdminConsultantListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consultoresAsync = ref.watch(adminConsultoresNotifierProvider);

    return PageScaffold(
      appBar: CadifeAppBar(
        title: 'Consultores',
        showProfile: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () => context.push('/agency/admin/consultants/new'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/agency/admin/consultants/new'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'NOVO CONSULTOR',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: consultoresAsync.when(
        data: (consultores) {
          if (consultores.isEmpty) {
            return const AppEmptyState(type: EmptyType.emptySearch);
          }
          return RefreshIndicator(
            onRefresh: () async => ref.read(adminConsultoresNotifierProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: consultores.length,
              itemBuilder: (context, index) => _ConsultorCard(
                consultor: consultores[index],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(
          type: ErrorType.genericError,
          onRetry: () => ref.read(adminConsultoresNotifierProvider.notifier).refresh(),
        ),
      ),
    );
  }
}

class _ConsultorCard extends ConsumerWidget {
  final ConsultorAdmin consultor;
  const _ConsultorCard({required this.consultor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final borderColor = isDark ? Colors.white10 : context.cadife.cardBorder;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onLongPress: () => _showOptionsModal(context, ref, consultor),
        child: ShadCard(
          padding: EdgeInsets.zero,
          backgroundColor: context.cadife.cardBackground,
          radius: BorderRadius.circular(12),
          border: ShadBorder.all(color: borderColor, width: 1),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: consultor.avatarUrl != null
                      ? NetworkImage(consultor.avatarUrl!)
                      : null,
                  child: consultor.avatarUrl == null
                      ? const Icon(LucideIcons.user, color: AppColors.primary)
                      : null,
                ),
                title: Text(
                  consultor.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  consultor.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.cadife.textSecondary,
                  ),
                ),
                trailing: _StatusToggle(
                  isActive: consultor.isActive,
                  onToggle: () => ref.read(adminConsultoresNotifierProvider.notifier).toggleStatus(consultor.id),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    _StatChip(
                      icon: LucideIcons.users,
                      label: '${consultor.leadsAtivos} ativos',
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      icon: LucideIcons.trendingUp,
                      label: '${(consultor.taxaConversao * 100).toStringAsFixed(0)}% conversão',
                      color: AppColors.success,
                    ),
                    const Spacer(),
                    if (consultor.receitaGerada != null)
                      Text(
                        'R\$ ${(consultor.receitaGerada! / 1000).toStringAsFixed(0)}k',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.cadife.textSecondary,
                        ),
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

  void _showOptionsModal(BuildContext context, WidgetRef ref, ConsultorAdmin consultor) {
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
                leading: const Icon(LucideIcons.pencil, color: AppColors.primary),
                title: const Text('Editar Consultor'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showEditModal(context, ref, consultor);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.trash2, color: AppColors.error),
                title: const Text('Excluir Consultor', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.of(context).pop();
                  _confirmDelete(context, ref, consultor);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditModal(BuildContext context, WidgetRef ref, ConsultorAdmin consultor) {
    final nameController = TextEditingController(text: consultor.name);
    final emailController = TextEditingController(text: consultor.email);
    final phoneController = TextEditingController(text: consultor.phone);

    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Editar Consultor'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShadInput(
                controller: nameController,
                placeholder: const Text('Nome completo'),
                leading: const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(LucideIcons.user, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              ShadInput(
                controller: emailController,
                placeholder: const Text('E-mail corporativo'),
                leading: const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(LucideIcons.mail, size: 18),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              ShadInput(
                controller: phoneController,
                placeholder: const Text('Telefone / WhatsApp'),
                leading: const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(LucideIcons.phone, size: 18),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: CadifeButton(
                  text: 'Salvar Alterações',
                  icon: LucideIcons.save,
                  analyticsLabel: 'admin_edit_consultor',
                  onPressed: () async {
                    final updated = consultor.copyWith(
                      name: nameController.text.trim(),
                      email: emailController.text.trim(),
                      phone: phoneController.text.trim(),
                    );
                    await ref.read(adminConsultoresNotifierProvider.notifier).updateConsultor(updated);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ShadToaster.of(context).show(
                        const ShadToast(description: Text('Consultor atualizado com sucesso!')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ConsultorAdmin consultor) {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: const Text('Excluir Consultor'),
        description: Text('Tem certeza que deseja excluir ${consultor.name}? Esta ação não pode ser desfeita.'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ShadButton.destructive(
            onPressed: () async {
              await ref.read(adminConsultoresNotifierProvider.notifier).deleteConsultor(consultor.id);
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

class _StatusToggle extends StatelessWidget {
  final bool isActive;
  final VoidCallback onToggle;

  const _StatusToggle({required this.isActive, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return ShadButton.ghost(
      size: ShadButtonSize.sm,
      onPressed: onToggle,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppColors.success : AppColors.zinc400,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Ativo' : 'Inativo',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.success : AppColors.zinc400,
            ),
          ),
        ],
      ),
    );
  }
}

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
