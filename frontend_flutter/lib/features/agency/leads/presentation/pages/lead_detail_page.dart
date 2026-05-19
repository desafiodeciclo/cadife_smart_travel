import 'package:cadife_smart_travel/config/router/routes.dart';
import 'package:cadife_smart_travel/core/analytics/analytics_service.dart';
import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/providers/lead_detail_provider.dart';
import 'package:cadife_smart_travel/l10n/app_localizations.dart';
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
                        const _ChatTimelineTab(),
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
            onPressed: () {},
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

class _BriefingTab extends StatelessWidget {
  final Lead lead;
  const _BriefingTab({required this.lead});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Briefing Tab Content'));
  }
}

class _ChatTimelineTab extends StatelessWidget {
  const _ChatTimelineTab();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Timeline Tab Content'));
  }
}

class _ProposalsHistoryTab extends StatelessWidget {
  final Lead lead;
  const _ProposalsHistoryTab({required this.lead});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Proposals Tab Content'));
  }
}