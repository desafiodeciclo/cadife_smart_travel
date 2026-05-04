part of 'agenda_page.dart';

// ─── Daily view ───────────────────────────────────────────────────────────────

class _DailyView extends ConsumerWidget {
  const _DailyView({required this.items});
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
        const Divider(height: 1, color: AppColors.divider),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: 7, // slots 09:00 → 15:00
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
            color: AppColors.textPrimary,
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
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: AppColors.textPrimary,
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      width: 1,
                      color: AppColors.divider,
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
    if (meeting!.status == 'bloqueado') {
      return _BlockedSlotCard(meeting: meeting!);
    }
    return _MeetingCard(meeting: meeting!);
  }
}

// ─── Meeting card ─────────────────────────────────────────────────────────────

class _MeetingCard extends StatelessWidget {
  const _MeetingCard({required this.meeting});
  final Agendamento meeting;

  @override
  Widget build(BuildContext context) {
    final endTime =
        meeting.dateTime.add(Duration(minutes: meeting.durationMinutes));
    final timeRange =
        '${DateFormat('HH:mm').format(meeting.dateTime)} – ${DateFormat('HH:mm').format(endTime)}';
    final displayName = meeting.notes?.isNotEmpty == true
        ? meeting.notes!
        : 'Reunião de Curadoria';

    return Material(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: meeting.leadId.isNotEmpty
            ? () => context.push('/agency/leads/${meeting.leadId}')
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: const Border(
              left: BorderSide(color: AppColors.primary, width: 3),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      timeRange,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(status: meeting.status),
              if (meeting.leadId.isNotEmpty) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status.toLowerCase()) {
      'agendado' => ('Agendado', AppColors.info),
      'realizado' => ('Realizado', AppColors.success),
      'cancelado' => ('Cancelado', AppColors.textSecondary),
      _ => (status, AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
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
    final label =
        meeting.notes?.isNotEmpty == true ? meeting.notes! : 'Horário Bloqueado';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline,
              size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.lock_open, size: 18),
            color: AppColors.warning,
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
          CadifeButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            text: 'Cancelar',
            isOutline: true,
          ),
          const SizedBox(height: 8),
          CadifeButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            text: 'Desbloquear',
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
          color: AppColors.scaffold,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text(
            'Disponível  ·  Toque para agendar ou bloquear',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  void _showSlotOptions(BuildContext context, WidgetRef ref, DateTime slot) {
    final notifier = ref.read(agendaProvider.notifier);

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Selecione um lead e agende para ${DateFormat('HH:mm').format(slot)}.',
              ),
            ),
          );
        },
        onBlock: (notes) async {
          Navigator.of(sheetContext).pop();
          await notifier.blockSlot(slot, notes: notes);
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
  final Future<void> Function(String? notes) onBlock;

  @override
  State<_SlotOptionsSheet> createState() => _SlotOptionsSheetState();
}

class _SlotOptionsSheetState extends State<_SlotOptionsSheet> {
  final _notesController = TextEditingController();
  bool _showNotesField = false;
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
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Horário $timeStr',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'O que deseja fazer com este horário?',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ListTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            tileColor: AppColors.primaryLight,
            leading:
                const Icon(Icons.event_available, color: AppColors.primary),
            title: const Text(
              'Agendar Reunião',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Vincular a um lead existente'),
            onTap: widget.onSchedule,
          ),
          const SizedBox(height: 8),
          ListTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            tileColor: AppColors.surface,
            leading: const Icon(Icons.do_not_disturb_on,
                color: AppColors.warning),
            title: const Text(
              'Bloquear Horário',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Pausa ou reunião interna'),
            trailing: _showNotesField
                ? null
                : const Icon(Icons.expand_more,
                    color: AppColors.textSecondary),
            onTap: () => setState(() => _showNotesField = true),
          ),
          if (_showNotesField) ...[
            const SizedBox(height: 8),
            CadifeInput(
              controller: _notesController,
              label: 'Motivo do bloqueio',
              hintText: 'Motivo (opcional)',
            ),
            const SizedBox(height: 8),
            CadifeButton(
              onPressed: _isBlocking
                  ? null
                  : () async {
                      setState(() => _isBlocking = true);
                      await widget.onBlock(
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
