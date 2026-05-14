part of 'agenda_page.dart';

// ─── Daily view ───────────────────────────────────────────────────────────────

class _DailyView extends ConsumerWidget {
  const _DailyView({required this.items, super.key});
  final List<Agendamento> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedAgendaDateProvider);

    final dayItems = items
        .where(
          (a) =>
              a.dateTime.year == selectedDate.year &&
              a.dateTime.month == selectedDate.month &&
              a.dateTime.day == selectedDate.day,
        )
        .toList();

    return Column(
      children: [
        _DayNavBar(selectedDate: selectedDate),
        const Divider(height: 1),
        Expanded(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -300) {
                // swipe left → próximo dia
                final d = ref.read(selectedAgendaDateProvider);
                ref.read(selectedAgendaDateProvider.notifier).state =
                    d.add(const Duration(days: 1));
              } else if (velocity > 300) {
                // swipe right → dia anterior
                final d = ref.read(selectedAgendaDateProvider);
                ref.read(selectedAgendaDateProvider.notifier).state =
                    d.subtract(const Duration(days: 1));
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              // slots 09:00 → 16:00 (8 slots)
              itemCount: 8,
              itemBuilder: (context, index) {
                final hour = 9 + index;
                final slotStart = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  hour,
                );

                final matching = dayItems.where((a) => a.dateTime.hour == hour);
                final meeting = matching.isEmpty ? null : matching.first;

                return _TimeSlotRow(
                  hour: hour,
                  slotStart: slotStart,
                  meeting: meeting,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _DayNavBar extends ConsumerWidget {
  const _DayNavBar({required this.selectedDate});
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayLabel =
        '${selectedDate.day.toString().padLeft(2, '0')} de ${_meses[selectedDate.month - 1]}, ${selectedDate.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: context.cadife.textPrimary,
            onPressed: () {
              final d = ref.read(selectedAgendaDateProvider);
              ref.read(selectedAgendaDateProvider.notifier).state =
                  d.subtract(const Duration(days: 1));
            },
          ),
          Expanded(
            child: Text(
              dayLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.cadife.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: context.cadife.textPrimary,
            onPressed: () {
              final d = ref.read(selectedAgendaDateProvider);
              ref.read(selectedAgendaDateProvider.notifier).state =
                  d.add(const Duration(days: 1));
            },
          ),
        ],
      ),
    );
  }
}

// ─── Time slot row ────────────────────────────────────────────────────────────

class _TimeSlotRow extends StatelessWidget {
  const _TimeSlotRow({
    required this.hour,
    required this.slotStart,
    required this.meeting,
  });

  final int hour;
  final DateTime slotStart;
  final Agendamento? meeting;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Text(
                  '${hour.toString().padLeft(2, '0')}:00',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.cadife.textSecondary,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      width: 1,
                      color: context.cadife.divider,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildSlotContent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotContent(BuildContext context) {
    if (meeting == null) {
      return _EmptySlotCard(slotStart: slotStart);
    }
    if (meeting!.isBloqueado) {
      return _BlockedSlotCard(meeting: meeting!);
    }
    if (meeting!.isCancelado) {
      return _CancelledSlotCard(meeting: meeting!);
    }
    return _MeetingCard(meeting: meeting!);
  }
}

// ─── Meeting card ─────────────────────────────────────────────────────────────

class _MeetingCard extends ConsumerWidget {
  const _MeetingCard({required this.meeting});
  final Agendamento meeting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final endTime =
        meeting.dateTime.add(Duration(minutes: meeting.durationMinutes));
    final timeRange =
        '${DateFormat('HH:mm').format(meeting.dateTime)} – ${DateFormat('HH:mm').format(endTime)}';
    final displayName =
        meeting.nomeCliente?.isNotEmpty == true
            ? meeting.nomeCliente!
            : (meeting.notas?.isNotEmpty == true
                ? meeting.notas!
                : 'Reunião de Curadoria');

    final statusColor = meeting.isBloqueado
        ? context.cadife.textSecondary
        : switch (meeting.statusEnum) {
            StatusAgendamento.pendente => AppColors.warning,
            StatusAgendamento.confirmado => Colors.blue,
            StatusAgendamento.realizado => AppColors.success,
            StatusAgendamento.cancelado => context.cadife.textSecondary,
          };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: meeting.leadId != null
            ? () => _openLeadSummary(context, ref)
            : null,
        onLongPress: () => _showLongPressMenu(context, ref),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(color: statusColor, width: 3),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: context.cadife.textPrimary,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (meeting.destinoViagem?.isNotEmpty == true)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: context.cadife.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              meeting.destinoViagem!,
                              style: TextStyle(
                                color: context.cadife.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 2),
                    Text(
                      timeRange,
                      style: TextStyle(
                        color: context.cadife.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusChip(status: meeting.status, color: statusColor),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: context.cadife.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openLeadSummary(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LeadSummarySheet(meeting: meeting),
    );
  }

  void _showLongPressMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => _MeetingActionsSheet(
        meeting: meeting,
        onEdit: () {
          Navigator.of(sheetCtx).pop();
          _openEditModal(context, ref);
        },
        onCancel: () async {
          Navigator.of(sheetCtx).pop();
          final confirmed = await _confirmCancel(context);
          if (confirmed == true && context.mounted) {
            final ok = await ref.read(agendaProvider.notifier).cancelSlot(meeting.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? 'Reunião cancelada' : 'Erro ao cancelar'),
                  backgroundColor: ok ? AppColors.success : AppColors.error,
                ),
              );
            }
          }
        },
        onViewLead: meeting.leadId != null
            ? () {
                Navigator.of(sheetCtx).pop();
                context.push('/agency/leads/${meeting.leadId}');
              }
            : null,
      ),
    );
  }

  void _openEditModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditSlotSheet(meeting: meeting),
    );
  }

  Future<bool?> _confirmCancel(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar reunião?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancelar reunião'),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, this.color});
  final String status;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ??
        switch (status.toLowerCase()) {
          'agendado' => Colors.blue,
          'realizado' => AppColors.success,
          'pendente' => AppColors.warning,
          _ => context.cadife.textSecondary,
        };

    final label = StatusAgendamento.values
        .firstWhere(
          (e) => e.name == status,
          orElse: () => StatusAgendamento.pendente,
        )
        .label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: resolvedColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: resolvedColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Meeting actions bottom sheet (long-press) ────────────────────────────────

class _MeetingActionsSheet extends StatelessWidget {
  const _MeetingActionsSheet({
    required this.meeting,
    required this.onEdit,
    required this.onCancel,
    required this.onViewLead,
  });

  final Agendamento meeting;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback? onViewLead;

  @override
  Widget build(BuildContext context) {
    final name = meeting.nomeCliente ?? 'Reunião de Curadoria';
    final time = DateFormat('HH:mm').format(meeting.dateTime);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          Text(
            '$name · $time',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.cadife.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _ActionTile(
            icon: Icons.edit_outlined,
            label: 'Editar agendamento',
            onTap: onEdit,
          ),
          if (onViewLead != null)
            _ActionTile(
              icon: Icons.person_outline,
              label: 'Ver perfil do lead',
              onTap: onViewLead,
            ),
          _ActionTile(
            icon: Icons.cancel_outlined,
            label: 'Cancelar reunião',
            color: AppColors.error,
            onTap: onCancel,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tileColor = color ?? context.cadife.textPrimary;
    return ListTile(
      leading: Icon(icon, color: tileColor, size: 22),
      title: Text(
        label,
        style: TextStyle(color: tileColor, fontWeight: FontWeight.w500),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: onTap,
      enabled: onTap != null,
    );
  }
}

// ─── Edit slot bottom sheet ───────────────────────────────────────────────────

class _EditSlotSheet extends ConsumerStatefulWidget {
  const _EditSlotSheet({required this.meeting});
  final Agendamento meeting;

  @override
  ConsumerState<_EditSlotSheet> createState() => _EditSlotSheetState();
}

class _EditSlotSheetState extends ConsumerState<_EditSlotSheet> {
  late final TextEditingController _notesCtrl;
  late String _selectedStatus;
  late int _selectedDuration;
  bool _isSaving = false;

  static const _durations = [30, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController(text: widget.meeting.notas ?? '');
    _selectedStatus = widget.meeting.status;
    _selectedDuration = widget.meeting.durationMinutes;
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text(
                'Editar Agendamento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.cadife.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_diasSemana[(widget.meeting.dateTime.weekday - 1) % 7]}, '
                  '${widget.meeting.dateTime.day.toString().padLeft(2, '0')} de '
                  '${_meses[widget.meeting.dateTime.month - 1]} · '
                  '${DateFormat('HH:mm').format(widget.meeting.dateTime)}',
                style: TextStyle(
                  color: context.cadife.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Status',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.cadife.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  StatusAgendamento.pendente,
                  StatusAgendamento.confirmado,
                  StatusAgendamento.realizado,
                ].map((s) {
                  final selected = _selectedStatus == s.name;
                  return ChoiceChip(
                    label: Text(s.label),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _selectedStatus = s.name),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.primary
                          : context.cadife.textSecondary,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text(
                'Duração',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.cadife.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _durations.map((d) {
                  final selected = _selectedDuration == d;
                  final label = d < 60
                      ? '$d min'
                      : d == 60
                          ? '1h'
                          : '${d ~/ 60}h${d % 60 > 0 ? '${d % 60}min' : ''}';
                  return ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _selectedDuration = d),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.primary
                          : context.cadife.textSecondary,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              CadifeInput(
                controller: _notesCtrl,
                label: 'Anotações (máx. 200 caracteres)',
                hintText: 'Observações sobre a reunião...',
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              CadifeButton(
                text: 'Salvar alterações',
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _save,
              ),
              const SizedBox(height: 8),
              CadifeButton(
                text: 'Cancelar',
                isOutline: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final ok = await ref.read(agendaProvider.notifier).editSlot(
          widget.meeting.id,
          UpdateAgendaRequest(
            status: _selectedStatus,
            notas: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
          ),
        );
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Reunião atualizada' : 'Erro ao salvar'),
          backgroundColor: ok ? AppColors.success : AppColors.error,
        ),
      );
    }
  }
}

// ─── Cancelled slot card ──────────────────────────────────────────────────────

class _CancelledSlotCard extends StatelessWidget {
  const _CancelledSlotCard({required this.meeting});
  final Agendamento meeting;

  @override
  Widget build(BuildContext context) {
    final name = meeting.nomeCliente ?? 'Reunião cancelada';
    final time = DateFormat('HH:mm').format(meeting.dateTime);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.cadife.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.cadife.cardBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.event_busy,
              size: 16, color: context.cadife.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$name · $time',
              style: TextStyle(
                color: context.cadife.textSecondary,
                fontSize: 13,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Blocked slot card ────────────────────────────────────────────────────────

class _BlockedSlotCard extends ConsumerWidget {
  const _BlockedSlotCard({required this.meeting});
  final Agendamento meeting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = meeting.motivoBloqueio?.label ??
        (meeting.notas?.isNotEmpty == true
            ? meeting.notas!
            : 'Horário Bloqueado');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.cadife.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.cadife.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: context.cadife.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.lock_open, size: 18),
            color: context.cadife.warning,
            tooltip: 'Desbloquear',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _confirmUnblock(context, ref, meeting),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmUnblock(
    BuildContext context,
    WidgetRef ref,
    Agendamento m,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Desbloquear horário?'),
        content: Text(
          'Deseja liberar ${DateFormat('HH:mm').format(m.dateTime)} para agendamentos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Desbloquear'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(agendaProvider.notifier).unblockSlot(m.id);
    }
  }
}

// ─── Empty slot card ──────────────────────────────────────────────────────────

class _EmptySlotCard extends ConsumerWidget {
  const _EmptySlotCard({required this.slotStart});
  final DateTime slotStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showSlotOptions(context, ref, slotStart),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: context.cadife.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.cadife.cardBorder),
        ),
        child: Center(
          child: Text(
            'Disponível  ·  Toque para agendar ou bloquear',
            style: TextStyle(
              color: context.cadife.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  void _showSlotOptions(BuildContext context, WidgetRef ref, DateTime slot) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => _SlotOptionsSheet(
        slotStart: slot,
        onSchedule: () {
          Navigator.of(sheetContext).pop();
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _LeadSelectSheet(slotStart: slot),
          );
        },
        onBlock: (motivo, notes) async {
          Navigator.of(sheetContext).pop();
          await ref.read(agendaProvider.notifier).blockSlot(
                slot,
                motivoBloqueio: motivo,
                notes: notes,
              );
        },
      ),
    );
  }
}

// ─── Slot options bottom sheet ────────────────────────────────────────────────

class _SlotOptionsSheet extends StatefulWidget {
  const _SlotOptionsSheet({
    required this.slotStart,
    required this.onSchedule,
    required this.onBlock,
  });

  final DateTime slotStart;
  final VoidCallback onSchedule;
  final Future<void> Function(MotivoBloqueio? motivo, String? notes) onBlock;

  @override
  State<_SlotOptionsSheet> createState() => _SlotOptionsSheetState();
}

class _SlotOptionsSheetState extends State<_SlotOptionsSheet> {
  final _notesController = TextEditingController();
  bool _showBlockForm = false;
  MotivoBloqueio? _selectedMotivo;
  bool _isBlocking = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(widget.slotStart);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Text(
            'Horário $timeStr',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.cadife.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'O que deseja fazer com este horário?',
            style:
                TextStyle(fontSize: 13, color: context.cadife.textSecondary),
          ),
          const SizedBox(height: 16),
          ListTile(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            tileColor: AppColors.primary.withValues(alpha: 0.1),
            leading: const Icon(Icons.event_available, color: Colors.blue),
            title: const Text(
              'Agendar Reunião',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Vincular a um lead existente'),
            onTap: widget.onSchedule,
          ),
          const SizedBox(height: 8),
          ListTile(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            tileColor: context.cadife.surface,
            leading:
                const Icon(Icons.do_not_disturb_on, color: Colors.orange),
            title: const Text(
              'Bloquear Horário',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Pausa ou reunião interna'),
            trailing: _showBlockForm
                ? null
                : Icon(Icons.expand_more,
                    color: context.cadife.textSecondary),
            onTap: () => setState(() => _showBlockForm = true),
          ),
          if (_showBlockForm) ...[
            const SizedBox(height: 12),
            Text(
              'Motivo',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.cadife.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: MotivoBloqueio.values.map((m) {
                final selected = _selectedMotivo == m;
                return ChoiceChip(
                  label: Text(m.label),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _selectedMotivo = m),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: selected
                        ? AppColors.primary
                        : context.cadife.textSecondary,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            if (_selectedMotivo == MotivoBloqueio.outro)
              CadifeInput(
                controller: _notesController,
                label: 'Descrição',
                hintText: 'Descreva o motivo...',
              ),
            const SizedBox(height: 8),
            CadifeButton(
              onPressed: _isBlocking || _selectedMotivo == null
                  ? null
                  : () async {
                      setState(() => _isBlocking = true);
                      await widget.onBlock(
                        _selectedMotivo,
                        _notesController.text.trim().isEmpty
                            ? null
                            : _notesController.text.trim(),
                      );
                    },
              text: 'Confirmar Bloqueio',
              isLoading: _isBlocking,
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
