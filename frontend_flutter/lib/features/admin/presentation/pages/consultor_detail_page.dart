import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/admin/domain/entities/admin_entities.dart';
import 'package:cadife_smart_travel/features/admin/presentation/providers/admin_providers.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/animated_tab_content.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/empty_state/empty_type.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/state_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ConsultorDetailPage extends ConsumerStatefulWidget {
  final String consultorId;
  const ConsultorDetailPage({required this.consultorId, super.key});

  @override
  ConsumerState<ConsultorDetailPage> createState() => _ConsultorDetailPageState();
}

class _ConsultorDetailPageState extends ConsumerState<ConsultorDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(consultorDetailProvider(widget.consultorId));

    return PageScaffold(
      showBackgroundEffects: false,
      extendBodyBehindAppBar: false,
      useSafeArea: false,
      body: StateContainer<ConsultorAdmin?>(
        state: detailAsync,
        onRetry: () => ref.refresh(consultorDetailProvider(widget.consultorId)),
        isEmpty: detailAsync.valueOrNull == null && detailAsync is AsyncData,
        customEmptyType: EmptyType.notFound,
        dataBuilder: (consultor) {
          if (consultor == null) return const SizedBox.shrink();
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                stretch: true,
                backgroundColor: AppColors.primary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.white),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    consultor.name,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      shadows: [Shadow(color: Colors.black38, blurRadius: 8)],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primary, AppColors.primaryDark],
                          ),
                        ),
                      ),
                      if (consultor.avatarUrl != null)
                        Image.network(
                          consultor.avatarUrl!,
                          fit: BoxFit.cover,
                          color: Colors.black45,
                          colorBlendMode: BlendMode.darken,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      // Avatar circular centralizado
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 16),
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              backgroundImage: consultor.avatarUrl != null
                                  ? NetworkImage(consultor.avatarUrl!)
                                  : null,
                              child: consultor.avatarUrl == null
                                  ? const Icon(LucideIcons.user, size: 36, color: Colors.white)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppColors.white),
                    onSelected: (value) {
                      if (value == 'edit') {
                        context.push('/agency/admin/consultants/${widget.consultorId}/edit');
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Editar Consultor'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _InfoCard(consultor: consultor),
                        const SizedBox(height: 16),
                        _ActionButtons(
                          consultorId: widget.consultorId,
                          consultor: consultor,
                        ),
                      ],
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: context.cadife.textSecondary,
                    indicatorColor: AppColors.primary,
                    tabs: const [
                      Tab(text: 'Estatísticas'),
                      Tab(text: 'Observações'),
                    ],
                  ),
                  SizedBox(
                    height: 500,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        AnimatedTabContent(
                          tabIndex: 0,
                          child: _StatsTab(consultor: consultor),
                        ),
                        const AnimatedTabContent(
                          tabIndex: 1,
                          child: _NotesTab(),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Info Card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final ConsultorAdmin consultor;
  const _InfoCard({required this.consultor});

  @override
  Widget build(BuildContext context) {
    final statusColor = consultor.isActive ? AppColors.success : AppColors.zinc400;

    return ShadCard(
      padding: EdgeInsets.zero,
      radius: BorderRadius.circular(12),
      border: ShadBorder.all(
        color: context.cadife.cardBorder.withValues(alpha: 0.5),
        width: 1,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 80,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        consultor.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.email_outlined,
                              size: 14, color: context.cadife.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            consultor.email,
                            style: TextStyle(
                              fontSize: 13,
                              color: context.cadife.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined,
                              size: 14, color: context.cadife.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            consultor.phone,
                            style: TextStyle(
                              fontSize: 13,
                              color: context.cadife.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ShadBadge(
                    backgroundColor: statusColor.withValues(alpha: 0.15),
                    foregroundColor: statusColor,
                    child: Text(consultor.isActive ? 'Ativo' : 'Inativo'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends ConsumerWidget {
  final String consultorId;
  final ConsultorAdmin consultor;
  const _ActionButtons({required this.consultorId, required this.consultor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: CadifeButton(
            text: 'Editar',
            icon: LucideIcons.pencil,
            analyticsLabel: 'consultor_detail_edit',
            onPressed: () =>
                context.push('/agency/admin/consultants/$consultorId/edit'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CadifeButton(
            text: consultor.isActive ? 'Desativar' : 'Ativar',
            icon: consultor.isActive ? LucideIcons.userX : LucideIcons.userCheck,
            variant: ButtonVariant.secondary,
            isOutline: true,
            analyticsLabel: 'consultor_detail_toggle_status',
            onPressed: () async {
              await ref
                  .read(consultorDetailProvider(consultorId).notifier)
                  .toggleStatus();
              if (context.mounted) {
                ShadToaster.of(context).show(
                  ShadToast(
                    description: Text(
                      consultor.isActive
                          ? 'Consultor desativado com sucesso.'
                          : 'Consultor ativado com sucesso.',
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

// ─── Stats Tab ────────────────────────────────────────────────────────────────

class _StatsTab extends StatelessWidget {
  final ConsultorAdmin consultor;
  const _StatsTab({required this.consultor});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Performance do Consultor',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.cadife.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _StatCard(
              icon: LucideIcons.users,
              title: 'Leads Ativos',
              value: consultor.leadsAtivos.toString(),
              color: AppColors.primary,
            ),
            _StatCard(
              icon: LucideIcons.clipboardList,
              title: 'Total Atendidos',
              value: (consultor.totalLeadsAtendidos ?? 0).toString(),
              color: AppColors.info,
            ),
            _StatCard(
              icon: LucideIcons.trendingUp,
              title: 'Taxa de Conversão',
              value: '${(consultor.taxaConversao * 100).toStringAsFixed(1)}%',
              color: AppColors.success,
            ),
            _StatCard(
              icon: LucideIcons.banknote,
              title: 'Receita Gerada',
              value: consultor.receitaGerada != null
                  ? 'R\$ ${(consultor.receitaGerada! / 1000).toStringAsFixed(0)}k'
                  : '—',
              color: AppColors.warning,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Progresso da Conversão',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.cadife.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ShadCard(
          padding: const EdgeInsets.all(16),
          radius: BorderRadius.circular(12),
          border: ShadBorder.all(
            color: context.cadife.cardBorder.withValues(alpha: 0.5),
            width: 1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(consultor.taxaConversao * 100).toStringAsFixed(1)}% de conversão',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    consultor.taxaConversao >= 0.7
                        ? 'Excelente'
                        : consultor.taxaConversao >= 0.5
                            ? 'Bom'
                            : 'Em desenvolvimento',
                    style: TextStyle(
                      fontSize: 12,
                      color: consultor.taxaConversao >= 0.7
                          ? AppColors.success
                          : consultor.taxaConversao >= 0.5
                              ? AppColors.warning
                              : context.cadife.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: consultor.taxaConversao,
                  minHeight: 8,
                  backgroundColor: context.cadife.cardBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    consultor.taxaConversao >= 0.7
                        ? AppColors.success
                        : consultor.taxaConversao >= 0.5
                            ? AppColors.warning
                            : AppColors.zinc400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      padding: const EdgeInsets.all(14),
      radius: BorderRadius.circular(12),
      border: ShadBorder.all(
        color: context.cadife.cardBorder.withValues(alpha: 0.4),
        width: 1,
      ),
      backgroundColor: context.cadife.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: context.cadife.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Notes Tab ────────────────────────────────────────────────────────────────

class _NotesTab extends StatelessWidget {
  const _NotesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Observações Internas',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.cadife.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        const ShadInput(
          maxLines: 5,
          placeholder: Text('Adicione notas ou observações sobre este consultor...'),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: ShadButton.ghost(
            onPressed: () {},
            child: const Text('Salvar Nota'),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Notas Anteriores',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.cadife.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ShadCard(
          padding: const EdgeInsets.all(16),
          radius: BorderRadius.circular(12),
          border: ShadBorder.all(
            color: context.cadife.cardBorder.withValues(alpha: 0.5),
            width: 1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.stickyNote, size: 14, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Nota — 01/05/2026',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.cadife.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Consultor com alto desempenho em vendas de pacotes premium. Especializado em destinos europeus.',
                style: TextStyle(fontSize: 13, color: context.cadife.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
