part of 'agenda_page.dart';

// ─── Lead summary bottom sheet ────────────────────────────────────────────────

class _LeadSummarySheet extends ConsumerWidget {
  const _LeadSummarySheet({required this.meeting});
  final Agendamento meeting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadsAsync = ref.watch(leadsNotifierProvider);

    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.cadife.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          leadsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.error_outline,
                      color: AppColors.error, size: 40),
                  SizedBox(height: 8),
                  Text('Não foi possível carregar dados do lead.'),
                ],
              ),
            ),
            data: (leads) {
              final lead = leads.cast<Lead?>().firstWhere(
                    (l) => l?.id == meeting.leadId,
                    orElse: () => null,
                  );
              return _LeadSummaryContent(meeting: meeting, lead: lead);
            },
          ),
        ],
      ),
    );
  }
}

class _LeadSummaryContent extends StatelessWidget {
  const _LeadSummaryContent({required this.meeting, required this.lead});
  final Agendamento meeting;
  final Lead? lead;

  @override
  Widget build(BuildContext context) {
    final name =
        lead?.name ?? meeting.nomeCliente ?? 'Lead não identificado';
    final destino =
        lead?.destino ?? meeting.destinoViagem ?? 'Destino não informado';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.cadife.textPrimary,
                      ),
                    ),
                    if (lead?.phone != null)
                      Text(
                        lead!.phone,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.cadife.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (lead != null)
                _LeadStatusBadge(status: lead!.status),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Info grid
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Destino',
            value: destino,
          ),
          if (lead?.dataIda != null) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Check-in',
              value: DateFormat('dd/MM/yyyy').format(lead!.dataIda!),
            ),
          ],
          if (lead?.dataVolta != null) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Check-out',
              value: DateFormat('dd/MM/yyyy').format(lead!.dataVolta!),
            ),
          ],
          if (lead?.numPessoas != null) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.group_outlined,
              label: 'Pessoas',
              value: '${lead!.numPessoas} pax',
            ),
          ],
          if (lead?.orcamentoFaixa != null) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.attach_money_outlined,
              label: 'Orçamento',
              value: lead!.orcamentoFaixa!,
            ),
          ],
          if (meeting.notas?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.notes_outlined,
              label: 'Anotações',
              value: meeting.notas!,
            ),
          ],
          const SizedBox(height: 20),

          // Reunião info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Reunião: ${DateFormat('HH:mm').format(meeting.dateTime)} '
                  '– ${DateFormat('HH:mm').format(meeting.dateTime.add(Duration(minutes: meeting.durationMinutes)))}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (lead != null)
            CadifeButton(
              text: 'Ver perfil completo',
              icon: Icons.arrow_forward,
              analyticsLabel: 'agenda_view_lead_profile',
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/agency/leads/${lead!.id}');
              },
            )
          else
            CadifeButton(
              text: 'Fechar',
              isOutline: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: context.cadife.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: context.cadife.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: context.cadife.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _LeadStatusBadge extends StatelessWidget {
  const _LeadStatusBadge({required this.status});
  final LeadStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      LeadStatus.novo => ('Novo', Colors.blue),
      LeadStatus.emAtendimento => ('Em Atendimento', AppColors.warning),
      LeadStatus.qualificado => ('Qualificado', AppColors.success),
      LeadStatus.agendado => ('Agendado', Colors.indigo),
      LeadStatus.proposta => ('Proposta', Colors.purple),
      LeadStatus.fechado => ('Fechado', AppColors.success),
      LeadStatus.perdido => ('Perdido', AppColors.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Lead select sheet ────────────────────────────────────────────────────────

class _LeadSelectSheet extends ConsumerStatefulWidget {
  const _LeadSelectSheet({required this.slotStart});
  final DateTime slotStart;

  @override
  ConsumerState<_LeadSelectSheet> createState() => _LeadSelectSheetState();
}

class _LeadSelectSheetState extends ConsumerState<_LeadSelectSheet> {
  String _search = '';
  bool _isScheduling = false;
  String? _schedulingId;
  // 0 = clientes, 1 = consultores (apenas admin)
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final leadsAsync = ref.watch(leadsNotifierProvider);
    final consultoresAsync = ref.watch(adminConsultantsProvider);
    final timeStr = DateFormat('HH:mm').format(widget.slotStart);
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final isAdmin = user?.role == UserRole.admin;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.cadife.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Agendar para $timeStr',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.cadife.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAdmin
                      ? 'Selecione o cliente ou consultor para a reunião'
                      : 'Selecione o cliente para vincular a esta reunião',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.cadife.textSecondary,
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 12),
                  ShadTabs<int>(
                    value: _tab,
                    onChanged: (v) => setState(() {
                      _tab = v;
                      _search = '';
                    }),
                    tabs: const [
                      ShadTab(
                        value: 0,
                        content: SizedBox.shrink(),
                        child: Text('Clientes'),
                      ),
                      ShadTab(
                        value: 1,
                        content: SizedBox.shrink(),
                        child: Text('Consultores'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                CadifeInput(
                  label: _tab == 1 ? 'Buscar consultor' : 'Buscar lead',
                  hintText:
                      _tab == 1 ? 'Nome do consultor...' : 'Nome do cliente...',
                  prefixIcon: Icons.search,
                  onChanged: (v) => setState(() => _search = v),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Expanded(
            child: isAdmin && _tab == 1
                ? _buildConsultoresTab(consultoresAsync)
                : _buildLeadsTab(leadsAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadsTab(AsyncValue<List<Lead>> leadsAsync) {
    return leadsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(
        child: Text('Não foi possível carregar os leads.'),
      ),
      data: (leads) {
        final eligible = leads
            .where(
              (l) =>
                  (l.status == LeadStatus.qualificado ||
                      l.status == LeadStatus.emAtendimento) &&
                  (_search.isEmpty ||
                      l.name.toLowerCase().contains(_search.toLowerCase())),
            )
            .toList();

        if (eligible.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_search,
                      size: 48, color: context.cadife.textSecondary),
                  const SizedBox(height: 12),
                  Text(
                    _search.isEmpty
                        ? 'Sem leads qualificados disponíveis'
                        : 'Nenhum lead encontrado',
                    style: TextStyle(
                      color: context.cadife.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: eligible.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final lead = eligible[index];
            final isLoading = _isScheduling && _schedulingId == lead.id;

            return _LeadSelectTile(
              lead: lead,
              isLoading: isLoading,
              onTap: _isScheduling ? null : () => _scheduleWithLead(lead),
            );
          },
        );
      },
    );
  }

  Widget _buildConsultoresTab(AsyncValue<List<AdminConsultant>> consultoresAsync) {
    return consultoresAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(
        child: Text('Não foi possível carregar os consultores.'),
      ),
      data: (consultores) {
        final eligible = consultores
            .where(
              (c) =>
                  c.isActive &&
                  (_search.isEmpty ||
                      c.name.toLowerCase().contains(_search.toLowerCase())),
            )
            .toList();

        if (eligible.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.manage_accounts,
                      size: 48, color: context.cadife.textSecondary),
                  const SizedBox(height: 12),
                  Text(
                    _search.isEmpty
                        ? 'Nenhum consultor ativo encontrado'
                        : 'Nenhum consultor encontrado',
                    style: TextStyle(
                      color: context.cadife.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: eligible.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final consultor = eligible[index];
            final isLoading =
                _isScheduling && _schedulingId == consultor.id;

            return _ConsultorSelectTile(
              consultor: consultor,
              isLoading: isLoading,
              onTap: _isScheduling
                  ? null
                  : () => _scheduleWithConsultor(consultor),
            );
          },
        );
      },
    );
  }

  Future<void> _scheduleWithLead(Lead lead) async {
    setState(() {
      _isScheduling = true;
      _schedulingId = lead.id;
    });

    final ok = await ref.read(agendaProvider.notifier).scheduleSlot(
          leadId: lead.id,
          dateTime: widget.slotStart,
        );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Reunião agendada com ${lead.name}'
                : 'Erro ao agendar. Tente novamente.',
          ),
          backgroundColor: ok ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _scheduleWithConsultor(AdminConsultant consultor) async {
    setState(() {
      _isScheduling = true;
      _schedulingId = consultor.id;
    });

    final ok = await ref.read(agendaProvider.notifier).scheduleSlot(
          dateTime: widget.slotStart,
          notes: 'Reunião com consultor: ${consultor.name}',
        );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Reunião agendada com ${consultor.name}'
                : 'Erro ao agendar. Tente novamente.',
          ),
          backgroundColor: ok ? AppColors.success : AppColors.error,
        ),
      );
    }
  }
}

// ─── Consultor select tile (admin only) ──────────────────────────────────────

class _ConsultorSelectTile extends StatelessWidget {
  const _ConsultorSelectTile({
    required this.consultor,
    required this.isLoading,
    required this.onTap,
  });

  final AdminConsultant consultor;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cadife.cardBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  consultor.name.isNotEmpty
                      ? consultor.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      consultor.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: context.cadife.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      consultor.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.cadife.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadSelectTile extends StatelessWidget {
  const _LeadSelectTile({
    required this.lead,
    required this.isLoading,
    required this.onTap,
  });

  final Lead lead;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cadife.cardBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  lead.name.isNotEmpty
                      ? lead.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: context.cadife.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    if (lead.destino?.isNotEmpty == true)
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 12,
                              color: context.cadife.textSecondary),
                          const SizedBox(width: 2),
                          Text(
                            lead.destino!,
                            style: TextStyle(
                              color: context.cadife.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
