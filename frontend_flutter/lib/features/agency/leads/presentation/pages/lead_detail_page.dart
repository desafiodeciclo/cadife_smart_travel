import 'package:cadife_smart_travel/config/router/routes.dart';
import 'package:cadife_smart_travel/core/analytics/analytics_service.dart';
import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/agenda/presentation/widgets/schedule_appointment_modal.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/briefing.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/conversation_summary.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/providers/lead_detail_provider.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/providers/leads_usecases_providers.dart';
import 'package:cadife_smart_travel/features/agency/propostas/presentation/widgets/proposals_history_tab.dart';
import 'package:cadife_smart_travel/l10n/app_localizations.dart';
import 'package:cadife_smart_travel/providers/leads_provider.dart';
import 'package:cadife_smart_travel/shared/domain/entities/interacao.dart';
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

  void _navigateToCreateProposal() {
    context.push(Routes.proposalCreate(widget.leadId));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(leadDetailProvider(widget.leadId), (previous, next) {
      if (next is AsyncData && previous?.value == null) {
        final lead = next.value;
        if (lead == null) return;
        sl<AnalyticsService>().logEvent('lead_viewed', parameters: {
          'lead_id': lead.id,
          'status': lead.status.name,
          'score': lead.score.name,
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
                  // Botão de Toggle da AYA
                  _AyaToggleAction(lead: lead),
                  // Menu de Opções
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppColors.white),
                    onSelected: (value) {
                      if (value == 'edit') {
                        context.push(Routes.leadEdit(widget.leadId));
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 20),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.editLead),
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
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _InfoCard(lead: lead),
                        const SizedBox(height: 16),
                        _ActionButtons(
                          lead: lead,
                          onCreateProposal: _navigateToCreateProposal,
                        ),
                      ],
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: context.cadife.textSecondary,
                    indicatorColor: AppColors.primary,
                    tabs: [
                      Tab(text: AppLocalizations.of(context)!.tabBriefing),
                      Tab(text: AppLocalizations.of(context)!.tabTimeline),
                      Tab(text: AppLocalizations.of(context)!.tabProposals),
                    ],
                  ),
                  SizedBox(
                    height: 600,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _BriefingTab(lead: lead),
                        _ChatTimelineTab(leadId: lead.id),
                        _ProposalsHistoryTab(lead: lead),
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

class _AyaToggleAction extends ConsumerWidget {
  final Lead lead;
  const _AyaToggleAction({required this.lead});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const Text('AYA', style: TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        Switch(
          value: lead.ayaAtivo,
          onChanged: (val) {
            ref.read(leadDetailProvider(lead.id).notifier).toggleAya(ativo: val);
          },
          activeThumbColor: AppColors.white,
          activeTrackColor: AppColors.success.withValues(alpha: 0.5),
        ),
      ],
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
                    child: Text(lead.status.name.replaceAll('_', ' '), style: TextStyle(color: statusColor)),
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

class _ActionButtons extends StatelessWidget {
  final Lead lead;
  final VoidCallback onCreateProposal;
  const _ActionButtons({required this.lead, required this.onCreateProposal});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ShadButton.outline(
            onPressed: () => ScheduleAppointmentModal.show(context, lead),
            child: Text(AppLocalizations.of(context)!.scheduleCall),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ShadButton(
            onPressed: onCreateProposal,
            child: Text(AppLocalizations.of(context)!.createProposal),
          ),
        ),
      ],
    );
  }
}

// ─── Briefing Tab ────────────────────────────────────────────────────────────

class _BriefingTab extends ConsumerWidget {
  final Lead lead;
  const _BriefingTab({required this.lead});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefingAsync = ref.watch(
      _briefingProvider(lead.id),
    );

    return StateContainer<Briefing>(
      state: briefingAsync,
      onRetry: () => ref.refresh(_briefingProvider(lead.id)),
      isEmpty: false,
      dataBuilder: (briefing) => _BriefingContent(briefing: briefing),
    );
  }
}

final _briefingProvider =
    FutureProvider.family<Briefing, String>((ref, leadId) async {
  final result = await ref.watch(getBriefingUseCaseProvider).call(leadId);
  return result.fold((f) => throw f, (b) => b);
});

class _BriefingContent extends StatelessWidget {
  final Briefing briefing;
  const _BriefingContent({required this.briefing});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Completude
        ShadCard(
          padding: const EdgeInsets.all(16),
          radius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Completude do Briefing',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.cadife.textPrimary,
                    ),
                  ),
                  Text(
                    '${briefing.completudePct}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _completudeColor(briefing.completudePct),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: briefing.completudePct / 100,
                  minHeight: 8,
                  backgroundColor:
                      _completudeColor(briefing.completudePct).withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(
                    _completudeColor(briefing.completudePct),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Dados da viagem
        ShadCard(
          padding: const EdgeInsets.all(16),
          radius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dados da Viagem',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              _BriefingRow(
                icon: Icons.place_outlined,
                label: 'Destino',
                value: briefing.destino,
              ),
              _BriefingRow(
                icon: Icons.flight_takeoff_outlined,
                label: 'Data de Ida',
                value: briefing.dataIda != null
                    ? dateFmt.format(briefing.dataIda!)
                    : null,
              ),
              _BriefingRow(
                icon: Icons.flight_land_outlined,
                label: 'Data de Volta',
                value: briefing.dataVolta != null
                    ? dateFmt.format(briefing.dataVolta!)
                    : null,
              ),
              _BriefingRow(
                icon: Icons.people_outline,
                label: 'Passageiros',
                value: briefing.numPessoas?.toString(),
              ),
              _BriefingRow(
                icon: Icons.card_travel_outlined,
                label: 'Tipo de Viagem',
                value: briefing.tipoViagem,
              ),
              _BriefingRow(
                icon: Icons.person_outline,
                label: 'Perfil',
                value: briefing.perfil,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Perfil e preferências
        ShadCard(
          padding: const EdgeInsets.all(16),
          radius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Preferências e Perfil',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              _BriefingRow(
                icon: Icons.attach_money_outlined,
                label: 'Orçamento',
                value: briefing.orcamentoFaixa,
              ),
              _BriefingRow(
                icon: Icons.book_outlined,
                label: 'Preferências',
                value: briefing.preferencias,
              ),
              _BriefingRow(
                icon: Icons.badge_outlined,
                label: 'Passaporte válido',
                value: briefing.passaporteValido == null
                    ? null
                    : briefing.passaporteValido!
                        ? 'Sim'
                        : 'Não',
              ),
              _BriefingRow(
                icon: Icons.public_outlined,
                label: 'Exp. internacional',
                value: briefing.experienciaInternacional == null
                    ? null
                    : briefing.experienciaInternacional!
                        ? 'Sim'
                        : 'Não',
              ),
            ],
          ),
        ),

        if (briefing.resumoConversa != null) ...[
          const SizedBox(height: 12),
          ShadCard(
            padding: const EdgeInsets.all(16),
            radius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumo da Conversa',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  briefing.resumoConversa!,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.cadife.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  Color _completudeColor(int pct) {
    if (pct >= 80) return AppColors.success;
    if (pct >= 50) return AppColors.warning;
    return AppColors.error;
  }
}

class _BriefingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;

  const _BriefingRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = (value == null || value!.isEmpty) ? '—' : value!;
    final isEmpty = value == null || value!.isEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.cadife.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isEmpty
                        ? context.cadife.textSecondary
                        : context.cadife.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Timeline Tab ─────────────────────────────────────────────────────────────

class _ChatTimelineTab extends ConsumerWidget {
  final String leadId;
  const _ChatTimelineTab({required this.leadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(_conversationSummaryProvider(leadId));
    final interacoesAsync = ref.watch(_interacoesProvider(leadId));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Resumo inteligente da conversa
        summaryAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, err) => const SizedBox.shrink(),
          data: (summary) {
            if (summary == null || summary.resumoPendente) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ShadCard(
                  padding: const EdgeInsets.all(16),
                  radius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome_outlined,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          summary?.resumoPendente == true
                              ? 'Resumo sendo gerado pela AYA…'
                              : 'Nenhum resumo disponível ainda.',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.cadife.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final r = summary.resumo;
            if (r == null) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ShadCard(
                padding: const EdgeInsets.all(16),
                radius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome_outlined,
                            color: AppColors.primary, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Resumo da AYA',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (r.intencaoPrincipal != null)
                      _SummaryTopic(
                          label: 'Intenção', value: r.intencaoPrincipal!),
                    if (r.datasEPassageiros != null)
                      _SummaryTopic(
                          label: 'Datas e passageiros',
                          value: r.datasEPassageiros!),
                    if (r.orcamento != null)
                      _SummaryTopic(
                          label: 'Orçamento', value: r.orcamento!),
                    if (r.restricoesEPreferencias != null)
                      _SummaryTopic(
                          label: 'Restrições',
                          value: r.restricoesEPreferencias!),
                    if (r.decisoesTomadas != null)
                      _SummaryTopic(
                          label: 'Decisões', value: r.decisoesTomadas!),
                    if (r.proximosPassos != null)
                      _SummaryTopic(
                          label: 'Próximos passos',
                          value: r.proximosPassos!),
                  ],
                ),
              ),
            );
          },
        ),

        // Timeline de interações
        interacoesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              'Erro ao carregar histórico',
              style: TextStyle(color: context.cadife.textSecondary),
            ),
          ),
          data: (interacoes) {
            if (interacoes.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Nenhuma interação registrada.',
                    style: TextStyle(color: context.cadife.textSecondary),
                  ),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Histórico de mensagens',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                ...interacoes.map((i) => _InteracaoItem(interacao: i)),
              ],
            );
          },
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

final _conversationSummaryProvider =
    FutureProvider.family<ConversationSummary?, String>((ref, leadId) async {
  final result =
      await ref.watch(getConversationSummaryUseCaseProvider).call(leadId);
  return result.fold((f) => throw f, (s) => s);
});

final _interacoesProvider =
    FutureProvider.family<List<Interacao>, String>((ref, leadId) async {
  final repo = ref.watch(leadsRepositoryProvider);
  final result = await repo.getInteractions(leadId);
  return result.fold((f) => throw f, (list) => list);
});

class _SummaryTopic extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryTopic({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  fontSize: 13, color: context.cadife.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _InteracaoItem extends StatelessWidget {
  final Interacao interacao;
  const _InteracaoItem({required this.interacao});

  @override
  Widget build(BuildContext context) {
    final isClient = interacao.direction == 'inbound';
    final dateFmt = DateFormat('dd/MM HH:mm');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha da timeline
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isClient ? AppColors.primary : AppColors.success,
                ),
              ),
              Container(
                width: 2,
                height: 40,
                color: context.cadife.textSecondary.withValues(alpha: 0.2),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isClient ? 'Cliente' : 'AYA',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: isClient
                            ? AppColors.primary
                            : AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateFmt.format(interacao.timestamp),
                      style: TextStyle(
                          fontSize: 11,
                          color: context.cadife.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  interacao.content,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Proposals Tab ────────────────────────────────────────────────────────────

class _ProposalsHistoryTab extends StatelessWidget {
  final Lead lead;
  const _ProposalsHistoryTab({required this.lead});

  @override
  Widget build(BuildContext context) {
    return ProposalsHistoryTab(lead: lead);
  }
}