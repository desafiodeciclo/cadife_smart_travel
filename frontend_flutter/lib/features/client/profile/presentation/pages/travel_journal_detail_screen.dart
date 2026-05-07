import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/profile/data/mocks/client_profile_mocks.dart';
import 'package:cadife_smart_travel/features/client/profile/domain/entities/diary_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

class TravelJournalDetailScreen extends ConsumerStatefulWidget {
  const TravelJournalDetailScreen({required this.tripId, super.key});

  final String tripId;

  @override
  ConsumerState<TravelJournalDetailScreen> createState() =>
      _TravelJournalDetailScreenState();
}

class _TravelJournalDetailScreenState
    extends ConsumerState<TravelJournalDetailScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  late List<DiaryEntry> _entries;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _entries = ClientProfileMocks.diaryEntries()
        .where((e) => e.tripId == widget.tripId)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _tripName() =>
      ClientProfileMocks.tripNames()[widget.tripId] ?? widget.tripId;

  List<List<DiaryEntry>> _groupIntoWeeks(List<DiaryEntry> entries) {
    if (entries.isEmpty) return [];
    final startDate = entries.first.date;
    final weeks = <List<DiaryEntry>>[];
    for (final entry in entries) {
      final difference = entry.date.difference(startDate).inDays;
      final weekIndex = difference ~/ 7;
      while (weeks.length <= weekIndex) {
        weeks.add([]);
      }
      weeks[weekIndex].add(entry);
    }
    return weeks;
  }

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final theme = Theme.of(context);
    final weeks = _groupIntoWeeks(_entries);

    return Scaffold(
      backgroundColor: cadife.background,
      appBar: AppBar(
        backgroundColor: cadife.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: cadife.textPrimary),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          _tripName(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: cadife.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? LucideIcons.check : LucideIcons.pencil,
              color: AppColors.primary,
            ),
            tooltip: _isEditing ? 'Concluir edição' : 'Editar diário',
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
        ],
      ),
      body: _entries.isEmpty
          ? _EmptyDiaryState(
              isEditing: _isEditing,
              onAddMemory: () => _showAddMemorySheet(context))
          : Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (page) =>
                        setState(() => _currentPage = page),
                    itemCount: weeks.length,
                    itemBuilder: (context, index) {
                      return _WeekPage(
                        weekIndex: index,
                        entries: weeks[index],
                        isEditing: _isEditing,
                        onEdit: (entry) =>
                            _showEditMemorySheet(context, entry),
                        onShare: _shareEntry,
                        onDelete: (entry) => _confirmDelete(context, entry),
                        onAddMemory: () => _showAddMemorySheet(context),
                      );
                    },
                  ),
                ),
                if (weeks.isNotEmpty)
                  _PageIndicatorBar(
                    current: _currentPage,
                    total: weeks.length,
                    onPrev: _currentPage > 0
                        ? () => _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            )
                        : null,
                    onNext: _currentPage < weeks.length - 1
                        ? () => _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            )
                        : null,
                  ),
              ],
            ),
    );
  }

  void _showAddMemorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMemorySheet(
        tripId: widget.tripId,
        onSaved: (entry) {
          setState(() {
            _entries.add(entry);
            _entries.sort((a, b) => a.date.compareTo(b.date));
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditMemorySheet(BuildContext context, DiaryEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditMemorySheet(
        entry: entry,
        onUpdated: (updated) {
          final idx = _entries.indexWhere((e) => e.id == updated.id);
          if (idx != -1) {
            setState(() {
              _entries[idx] = updated;
              _entries.sort((a, b) => a.date.compareTo(b.date));
            });
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _shareEntry(DiaryEntry entry) async {
    final token = entry.sharingToken ?? const Uuid().v4();
    final link = 'https://cadife.app/diary/$token';
    await SharePlus.instance.share(
      ShareParams(
        text: 'Veja minha memória de viagem: $link',
        subject: 'Memória de viagem — ${_tripName()}',
      ),
    );
    final idx = _entries.indexWhere((e) => e.id == entry.id);
    if (idx != -1) {
      setState(() {
        _entries[idx] = entry.copyWith(sharingToken: token, isShared: true);
      });
    }
  }

  Future<void> _confirmDelete(BuildContext context, DiaryEntry entry) async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (ctx) => ShadDialog(
        title: const Text('Deletar memória?'),
        description: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ShadButton.destructive(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() {
        _entries.removeWhere((e) => e.id == entry.id);
        final weeks = _groupIntoWeeks(_entries);
        if (_currentPage >= weeks.length && _currentPage > 0) {
          _currentPage = weeks.length - 1;
        }
      });
    }
  }
}

// ---------------------------------------------------------------------------
// Week page
// ---------------------------------------------------------------------------

class _WeekPage extends StatelessWidget {
  const _WeekPage({
    required this.weekIndex,
    required this.entries,
    required this.isEditing,
    required this.onEdit,
    required this.onShare,
    required this.onDelete,
    required this.onAddMemory,
  });

  final int weekIndex;
  final List<DiaryEntry> entries;
  final bool isEditing;
  final void Function(DiaryEntry) onEdit;
  final void Function(DiaryEntry) onShare;
  final void Function(DiaryEntry) onDelete;
  final VoidCallback onAddMemory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cadife = context.cadife;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Semana ${weekIndex + 1}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: cadife.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'Nenhuma memória nesta semana.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cadife.textSecondary,
                ),
              ),
            ),
          )
        else
          ...entries.map((entry) => _DiaryEntryItem(
                entry: entry,
                isEditing: isEditing,
                onEdit: () => onEdit(entry),
                onShare: () => onShare(entry),
                onDelete: () => onDelete(entry),
              )),
        if (isEditing) ...[
          const SizedBox(height: 16),
          CadifeButton(
            text: 'Adicionar memória',
            icon: Icons.add,
            onPressed: onAddMemory,
          ),
        ],
      ],
    );
  }
}

class _DiaryEntryItem extends StatelessWidget {
  const _DiaryEntryItem({
    required this.entry,
    required this.isEditing,
    required this.onEdit,
    required this.onShare,
    required this.onDelete,
  });

  final DiaryEntry entry;
  final bool isEditing;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  String _formattedDate(DateTime d) {
    const months = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
    ];
    return '${d.day} de ${months[d.month - 1]} de ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final theme = Theme.of(context);

    return Card(
      color: cadife.cardBackground,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cadife.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    entry.photoUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      width: 100,
                      height: 100,
                      color: cadife.muted,
                      child: Icon(LucideIcons.imageOff, color: cadife.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.calendar, size: 12, color: cadife.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            _formattedDate(entry.date),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cadife.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (entry.isShared) ...[
                            const SizedBox(width: 8),
                            _SharedBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.note,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cadife.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isEditing) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: LucideIcons.pencil,
                      label: 'Editar',
                      onTap: onEdit,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      icon: LucideIcons.trash2,
                      label: 'Deletar',
                      onTap: onDelete,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(LucideIcons.share2, size: 20, color: cadife.textSecondary),
                  onPressed: onShare,
                  tooltip: 'Compartilhar',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SharedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.share2, size: 8, color: AppColors.success),
          const SizedBox(width: 4),
          Text(
            'Compartilhado',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final theme = Theme.of(context);
    final effectiveColor = color ?? cadife.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: effectiveColor.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: effectiveColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: effectiveColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page indicator
// ---------------------------------------------------------------------------

class _PageIndicatorBar extends StatelessWidget {
  const _PageIndicatorBar({
    required this.current,
    required this.total,
    required this.onPrev,
    required this.onNext,
  });

  final int current;
  final int total;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: cadife.cardBackground,
        border: Border(top: BorderSide(color: cadife.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Semana ${current + 1} de $total',
            style: theme.textTheme.labelMedium?.copyWith(
              color: cadife.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(LucideIcons.chevronLeft,
                    size: 20, color: cadife.textPrimary),
                onPressed: onPrev,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: Icon(LucideIcons.chevronRight,
                    size: 20, color: cadife.textPrimary),
                onPressed: onNext,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyDiaryState extends StatelessWidget {
  const _EmptyDiaryState({required this.isEditing, required this.onAddMemory});

  final bool isEditing;
  final VoidCallback onAddMemory;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.cameraOff,
                size: 64,
                color: cadife.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 20),
            Text(
              'Nenhuma memória ainda',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cadife.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Registre seus momentos especiais nesta viagem',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cadife.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            if (isEditing)
              CadifeButton(
                text: 'Adicionar memória',
                icon: Icons.add,
                onPressed: onAddMemory,
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add memory bottom sheet
// ---------------------------------------------------------------------------

class _AddMemorySheet extends StatefulWidget {
  const _AddMemorySheet({required this.tripId, required this.onSaved});

  final String tripId;
  final void Function(DiaryEntry entry) onSaved;

  @override
  State<_AddMemorySheet> createState() => _AddMemorySheetState();
}

class _AddMemorySheetState extends State<_AddMemorySheet> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: cadife.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SheetHandle(),
              Text(
                'Adicionar memória',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cadife.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => ShadToaster.of(context).show(
                  const ShadToast(
                    description: Text('Upload de foto disponível em breve'),
                  ),
                ),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: cadife.muted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cadife.divider),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.imagePlus,
                            size: 40, color: cadife.textSecondary),
                        const SizedBox(height: 8),
                        Text(
                          'Selecionar foto',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: cadife.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _NoteField(
                controller: _noteController,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CadifeButton(
                      text: 'Cancelar',
                      isOutline: true,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CadifeButton(
                      text: 'Salvar',
                      onPressed: _noteController.text.trim().isEmpty
                          ? null
                          : _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final entry = DiaryEntry(
      id: const Uuid().v4(),
      tripId: widget.tripId,
      photoUrl:
          'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=600',
      note: _noteController.text.trim(),
      date: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    widget.onSaved(entry);
  }
}

// ---------------------------------------------------------------------------
// Edit memory bottom sheet
// ---------------------------------------------------------------------------

class _EditMemorySheet extends StatefulWidget {
  const _EditMemorySheet({required this.entry, required this.onUpdated});

  final DiaryEntry entry;
  final void Function(DiaryEntry updated) onUpdated;

  @override
  State<_EditMemorySheet> createState() => _EditMemorySheetState();
}

class _EditMemorySheetState extends State<_EditMemorySheet> {
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.entry.note);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: cadife.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SheetHandle(),
              Text(
                'Editar memória',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cadife.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.entry.photoUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 140,
                    color: cadife.muted,
                    child: Icon(LucideIcons.imageOff,
                        color: cadife.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _NoteField(controller: _noteController),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CadifeButton(
                      text: 'Cancelar',
                      isOutline: true,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CadifeButton(
                      text: 'Atualizar',
                      onPressed: _update,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _update() {
    widget.onUpdated(
      widget.entry.copyWith(
        note: _noteController.text.trim(),
        updatedAt: DateTime.now(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: context.cadife.divider,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller, this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nota',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cadife.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 4,
          maxLength: 300,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Escreva sobre este momento...',
            hintStyle: TextStyle(color: cadife.textSecondary),
            filled: true,
            fillColor: cadife.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cadife.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cadife.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
