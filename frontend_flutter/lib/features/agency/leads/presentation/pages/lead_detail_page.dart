import 'dart:async';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/providers/leads_usecases_providers.dart';
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
    context.push('/agency/proposals/${widget.leadId}/new');
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
                  // Botão de Toggle da AYA
                  _AyaToggleAction(lead: lead),
                  // Menu de Opções
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppColors.white),
                    onSelected: (value) {
                      if (value == 'edit') {
                        context.push('/agency/leads/${widget.leadId}/edit');
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Editar Lead'),
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
                    tabs: const [
                      Tab(text: 'Briefing'),
                      Tab(text: 'Timeline'),
                      Tab(text: 'Propostas'),
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
                          child: ProposalsHistoryTab(lead: lead),
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

class LeadDetailNotifier extends FamilyAsyncNotifier<Lead?, String> {
  @override
  FutureOr<Lead?> build(String arg) async {
    final getLead = ref.watch(getLeadByIdUseCaseProvider);
    final result = await getLead(arg);

    return result.fold(
      (failure) => throw failure,
      (lead) => lead,
    );
  }

  /// Gerencia o estado da IA Aya (Ação do Switch na AppBar)
  Future<void> toggleAya({required bool ativo, String? motivo}) async {
    final leadId = arg;
    final toggleUseCase = ref.read(toggleAyaUseCaseProvider);

    // Otimismo na UI: Atualiza o estado local antes da resposta do servidor
    final previousState = state.value;
    if (previousState != null) {
      state = AsyncData(previousState.copyWith(ayaAtivo: ativo));
    }

    final result = await toggleUseCase(leadId, ativo: ativo, motivo: motivo);

    result.fold(
      (failure) {
        // Rollback em caso de erro
        state = AsyncData(previousState);
      },
      (_) => ref.invalidateSelf(), // Recarrega para garantir sincronia
    );
  }

  /// Atualiza o status do lead (Ação de Aprovar/Agendar)
  Future<void> updateStatus(LeadStatus newStatus) async {
    final updateUseCase = ref.read(updateLeadStatusUseCaseProvider);
    
    final result = await updateUseCase(arg, newStatus);
    
    result.fold(
      (failure) => null, // O Toaster na UI tratará o feedback
      (updatedLead) => state = AsyncData(updatedLead),
    );
  }
}