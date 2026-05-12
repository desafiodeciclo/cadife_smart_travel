import 'package:cadife_smart_travel/core/analytics/analytics_service.dart';
import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/admin/domain/entities/admin_entities.dart';
import 'package:cadife_smart_travel/features/admin/presentation/providers/admin_providers.dart';
import 'package:cadife_smart_travel/features/agency/agenda/presentation/widgets/schedule_appointment_modal.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/providers/lead_detail_provider.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/providers/leads_notifier.dart';
import 'package:cadife_smart_travel/features/agency/propostas/presentation/widgets/proposal_form_tab.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/animated_tab_content.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/empty_state/empty_type.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/state_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LeadDetailPage extends ConsumerStatefulWidget {
  final String leadId;
  const LeadDetailPage({required this.leadId, super.key});

  @override
  ConsumerState<LeadDetailPage> createState() => _LeadDetailPageState();
}

class _LeadDetailPageState extends ConsumerState<LeadDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _goToProposalTab() => _tabController.animateTo(2);

  @override
  Widget build(BuildContext context) {
    ref.listen(leadDetailProvider(widget.leadId), (previous, next) {
      if (next is AsyncData && previous?.value == null) {
        final lead = next.value;
        if (lead == null) return;
        sl<AnalyticsService>().logEvent('lead_viewed', parameters: {
          'lead_id': lead.id,
          'status': lead.status.name,
          'score': lead.score,
        });
      }
    });

    final detailAsync = ref.watch(leadDetailProvider(widget.leadId));

    return PageScaffold(
      showBackgroundEffects: false,
      extendBodyBehindAppBar: false,
      useSafeArea: false,
      body: StateContainer<Lead?>(
        state: detailAsync,
        onRetry: () => ref.refresh(leadDetailProvider(widget.leadId)),
        isEmpty: detailAsync.valueOrNull == null && detailAsync is AsyncData,
        customEmptyType: EmptyType.notFound,
        dataBuilder: (lead) {
          if (lead == null) return const SizedBox.shrink();
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                stretch: true,
                backgroundColor: context.cadife.primary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.white),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    lead.name,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: AppColors.overlayMedium, blurRadius: 10)],
                    ),
                  ),
                  background: lead.imageUrl != null
                      ? Hero(
                          tag: 'lead_image_${lead.id}',
                          child: Image.network(
                            lead.imageUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(color: context.cadife.primary),
                ),
                actions: [
                  _AyaToggleAction(lead: lead),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: AppColors.white),
                    onPressed: () {},
                  ),
                ],
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _InfoCard(lead: lead),
                        const SizedBox(height: 16),
                        _ActionButtons(
                          lead: lead,
                          onCreateProposal: _goToProposalTab,
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
                      Tab(text: 'Briefing'),
                      Tab(text: 'Timeline'),
                      Tab(text: 'Proposta'),
                    ],
                  ),
                  SizedBox(
                    height: 600,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        AnimatedTabContent(
                          tabIndex: 0,
                          child: _BriefingTab(lead: lead),
                        ),
                        const AnimatedTabContent(
                          tabIndex: 1,
                          child: _ChatTimelineTab(),
                        ),
                        AnimatedTabContent(
                          tabIndex: 2,
                          child: ProposalFormTab(lead: lead),
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


class _InfoCard extends StatelessWidget {
  final Lead lead;
  const _InfoCard({required this.lead});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.statusColor(lead.status.name);

    return ShadCard(
      padding: EdgeInsets.zero,
      radius: BorderRadius.circular(12),
      border: ShadBorder.all(color: context.cadife.cardBorder.withValues(alpha: 0.5), width: 1),
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
                        lead.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined, size: 14, color: context.cadife.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            lead.phone,
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
                    child: Text(lead.status.name.replaceAll('_', ' ')),
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

class _ActionButtons extends ConsumerWidget {
  final Lead lead;
  final VoidCallback onCreateProposal;
  const _ActionButtons({required this.lead, required this.onCreateProposal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final isAdmin = user?.role == UserRole.admin;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CadifeButton(
                text: 'Aprovar',
                icon: Icons.check_circle_outline,
                analyticsLabel: 'lead_detail_approve',
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CadifeButton(
                text: 'Criar Proposta',
                icon: Icons.description_outlined,
                variant: ButtonVariant.secondary,
                isOutline: true,
                analyticsLabel: 'lead_detail_create_proposal',
                onPressed: onCreateProposal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CadifeButton(
                text: 'Agendar',
                icon: Icons.calendar_today_outlined,
                variant: ButtonVariant.secondary,
                isOutline: true,
                analyticsLabel: 'lead_detail_schedule',
                onPressed: () async {
                  final result = await ScheduleAppointmentModal.show(context, lead);
                  if (result == true) {
                    await ref.read(leadDetailProvider(lead.id).notifier).updateStatus(LeadStatus.agendado);
                    if (context.mounted) {
                      ShadToaster.of(context).show(
                        const ShadToast(description: Text('Agendamento realizado com sucesso!')),
                      );
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: isAdmin
                  ? CadifeButton(
                      text: 'Reatribuir',
                      icon: LucideIcons.userCog,
                      variant: ButtonVariant.secondary,
                      isOutline: true,
                      analyticsLabel: 'lead_detail_reassign',
                      onPressed: () => _showReassignModal(context, ref, lead),
                    )
                  : CadifeButton(
                      text: 'WhatsApp',
                      icon: Icons.chat_bubble_outline,
                      variant: ButtonVariant.secondary,
                      isOutline: true,
                      analyticsLabel: 'lead_detail_whatsapp',
                      onPressed: () {},
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showReassignModal(BuildContext context, WidgetRef ref, Lead lead) async {
    final consultoresAsync = ref.read(adminConsultoresProvider);
    final consultores = consultoresAsync.valueOrNull ?? [];
    final activeConsultores = consultores.where((c) => c.isActive).toList();

    if (activeConsultores.isEmpty) {
      if (context.mounted) {
        ShadToaster.of(context).show(
          const ShadToast(
            description: Text('Nenhum consultor ativo disponível para reatribuição.'),
          ),
        );
      }
      return;
    }

    ConsultorAdmin? selected;

    await showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Reatribuir Lead'),
        description: Text('Selecione o novo consultor para atender ${lead.name}:'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            ...activeConsultores.map((c) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ShadButton.outline(
                  width: double.infinity,
                  onPressed: () {
                    selected = c;
                    Navigator.of(context).pop();
                  },
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundImage: c.avatarUrl != null ? NetworkImage(c.avatarUrl!) : null,
                    child: c.avatarUrl == null ? const Icon(LucideIcons.user, size: 14) : null,
                  ),
                  child: Text('${c.name} (${c.leadsAtivos} ativos)'),
                ),
              );
            }),
          ],
        ),
      ),
    );

    if (selected != null && context.mounted) {
      await ref.read(leadsNotifierProvider.notifier).reassignLead(lead.id, selected!.name);
      ref.invalidate(leadDetailProvider(lead.id));
      if (context.mounted) {
        ShadToaster.of(context).show(
          ShadToast(
            description: Text('Lead reatribuído para ${selected!.name}'),
          ),
        );
      }
    }
  }
}

class _BriefingTab extends StatelessWidget {
  final Lead lead;
  const _BriefingTab({required this.lead});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Briefing Estruturado',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.cadife.textSecondary),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: [
            _GridItem(icon: Icons.flight_takeoff, title: 'Destino', value: lead.destino ?? 'Não informado'),
            const _GridItem(icon: Icons.calendar_month, title: 'Datas', value: '10 a 20 Fev 2026'),
            _GridItem(icon: Icons.people_outline, title: 'Pessoas', value: '${lead.numPessoas ?? 0} (Familia)'),
            _GridItem(icon: Icons.account_balance_wallet_outlined, title: 'Orçamento', value: lead.orcamentoFaixa ?? 'Médio'),
            _GridItem(icon: Icons.badge_outlined, title: 'Passaporte Válido', value: lead.passaporteValido == true ? 'Sim, todos' : 'Não informado'),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Observações',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.cadife.textSecondary),
        ),
        const SizedBox(height: 12),
        const ShadInput(
          maxLines: 4,
          placeholder: Text('Adicione notas sobre o atendimento...'),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: ShadButton.ghost(
            onPressed: () {},
            child: const Text('Salvar Nota'),
          ),
        ),
      ],
    );
  }
}

class _GridItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _GridItem({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      padding: const EdgeInsets.all(12),
      radius: BorderRadius.circular(12),
      border: ShadBorder.all(color: context.cadife.cardBorder.withValues(alpha: 0.3), width: 1),
      backgroundColor: context.cadife.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 12, color: context.cadife.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ChatTimelineTab extends StatelessWidget {
  const _ChatTimelineTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Timeline de Status',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.cadife.textSecondary),
        ),
        const SizedBox(height: 16),
        ShadCard(
          padding: const EdgeInsets.all(16),
          radius: BorderRadius.circular(12),
          border: ShadBorder.all(color: context.cadife.cardBorder.withValues(alpha: 0.5), width: 1),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TimelineItem(title: 'Qualificado', subtitle: 'Hoje, 10:15', isLast: false, isActive: true),
              _TimelineItem(title: 'Em Atendimento', subtitle: 'Hoje, 09:05', isLast: false),
              _TimelineItem(title: 'Novo Lead', subtitle: 'Hoje, 09:00', isLast: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isLast;
  final bool isActive;

  const _TimelineItem({required this.title, required this.subtitle, required this.isLast, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? AppColors.primary : AppColors.primary.withValues(alpha: 0.2),
                  border: isActive ? Border.all(color: AppColors.primary, width: 2) : null,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      color: isActive ? context.cadife.textPrimary : context.cadife.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: context.cadife.textSecondary),
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
class _AyaToggleAction extends ConsumerWidget {
  final Lead lead;
  const _AyaToggleAction({required this.lead});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'AYA',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(
              height: 24,
              child: Switch(
                value: lead.ayaAtivo,
                activeThumbColor: AppColors.white,
                activeTrackColor: Colors.green.shade400,
                inactiveThumbColor: AppColors.white,
                inactiveTrackColor: Colors.grey.shade400,
                onChanged: (value) => _handleToggle(context, ref, value),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Future<void> _handleToggle(BuildContext context, WidgetRef ref, bool newValue) async {
    if (!newValue) {
      // Confirm desactivation
      final motivoController = TextEditingController();
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => ShadDialog(
          title: const Text('Desativar AYA?'),
          description: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ao desativar a AYA, você assume o atendimento manual deste cliente. A IA não responderá mais automaticamente.',
              ),
              const SizedBox(height: 16),
              ShadInput(
                controller: motivoController,
                placeholder: const Text('Motivo (ex: Atendimento manual)'),
              ),
            ],
          ),
          actions: [
            ShadButton.ghost(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ShadButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Desativar'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await ref.read(leadDetailProvider(lead.id).notifier).toggleAya(
              ativo: false,
              motivo: motivoController.text.isNotEmpty ? motivoController.text : 'Atendimento manual',
            );
        if (context.mounted) {
          ShadToaster.of(context).show(
            const ShadToast(description: Text('AYA desativada para esta conversa.')),
          );
        }
      }
    } else {
      // Reactivate
      await ref.read(leadDetailProvider(lead.id).notifier).toggleAya(ativo: true);
      if (context.mounted) {
        ShadToaster.of(context).show(
          const ShadToast(description: Text('AYA reativada. O contexto foi preservado.')),
        );
      }
    }
  }
}
