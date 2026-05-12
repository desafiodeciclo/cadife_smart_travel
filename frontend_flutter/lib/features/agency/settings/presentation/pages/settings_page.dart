import 'dart:async';

import 'package:cadife_smart_travel/core/network/dio_provider.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/settings/domain/entities/agency_settings.dart';
import 'package:cadife_smart_travel/features/agency/settings/presentation/providers/settings_notifier.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:cadife_smart_travel/features/settings/application/theme_notifier.dart';
import 'package:cadife_smart_travel/features/settings/domain/entities/user_preferences.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ── Main Page ─────────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  AgencySettings? _draft;
  AgencySettings? _saved;
  Timer? _saveTimer;
  bool _isSaving = false;
  bool _saveTimerActive = false;

  bool get _hasChanges =>
      _draft != null && _saved != null && _draft != _saved;

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  void _updateDraft(AgencySettings Function(AgencySettings) updater) {
    if (_draft == null) return;
    setState(() => _draft = updater(_draft!));
  }

  void _onSavePressed() {
    if (!_hasChanges || _isSaving || _saveTimerActive) return;
    _saveTimer?.cancel();
    setState(() => _saveTimerActive = true);
    _saveTimer = Timer(const Duration(milliseconds: 1500), _doSave);
  }

  Future<void> _doSave() async {
    if (!mounted) return;
    setState(() {
      _saveTimerActive = false;
      _isSaving = true;
    });
    final error =
        await ref.read(agencySettingsProvider.notifier).saveAll(_draft!);
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      if (error == null) _saved = _draft;
    });
    final messenger = ScaffoldMessenger.of(context);
    if (error == null) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Configurações salvas com sucesso'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(error),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Tentar novamente',
          textColor: Colors.white,
          onPressed: _onSavePressed,
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(agencySettingsProvider);

    // Initialise draft from first available data (sync or async path)
    final data = settingsAsync.valueOrNull;
    if (data != null && _draft == null) {
      _draft = data;
      _saved = data;
    }

    // Also listen for future refreshes (e.g. pull-to-refresh)
    ref.listen<AsyncValue<AgencySettings>>(agencySettingsProvider, (_, next) {
      final s = next.valueOrNull;
      if (s != null && _draft == null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _draft = s;
              _saved = s;
            });
          }
        });
      }
    });

    return PageScaffold(
      appBar: const CadifeAppBar(
        title: 'Configurações',
        showProfile: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _draft != null
                ? _buildBody()
                : settingsAsync.when(
                    loading: () => const AppLoadingWidget(),
                    error: (e, _) => AppErrorWidget(
                      message: 'Erro ao carregar configurações',
                      onRetry: () => ref.invalidate(agencySettingsProvider),
                    ),
                    data: (_) => const AppLoadingWidget(),
                  ),
          ),
          if (_draft != null) _buildSaveBar(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final d = _draft!;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      children: [
        _NotificationsSection(
          prefs: d.notifications,
          onChanged: (p) =>
              _updateDraft((s) => s.copyWith(notifications: p)),
        ),
        _OfficeHoursSection(
          hours: d.officeHours.where((h) => h.weekday >= 1 && h.weekday <= 5).toList(),
          onChanged: (updated) {
            final all = d.officeHours.map((h) {
              final match = updated.firstWhere(
                (u) => u.weekday == h.weekday,
                orElse: () => h,
              );
              return match;
            }).toList();
            _updateDraft((s) => s.copyWith(officeHours: all));
          },
        ),
        _TemplatesSection(
          templates: d.templates,
          onChanged: (templates) =>
              _updateDraft((s) => s.copyWith(templates: templates)),
        ),
        _SecuritySection(),
        const _ThemeSection(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSaveBar() {
    final isLoading = _isSaving || _saveTimerActive;
    final isActive = _hasChanges && !isLoading;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: context.cadife.cardBorder, width: 1),
          ),
        ),
        child: ShadButton(
          onPressed: isActive ? _onSavePressed : null,
          width: double.infinity,
          child: isLoading
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('Salvando...'),
                  ],
                )
                : const Text('Salvar Alterações'),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ShadCard(
        padding: const EdgeInsets.all(24),
        backgroundColor: isDark ? context.cadife.cardBackground : Colors.white,
        radius: BorderRadius.circular(24),
        border: ShadBorder.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : context.cadife.cardBorder,
          width: 1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w800,
                    color: context.cadife.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ── Notifications Section ─────────────────────────────────────────────────────

class _NotificationsSection extends StatelessWidget {
  const _NotificationsSection({
    required this.prefs,
    required this.onChanged,
  });

  final NotificationPrefs prefs;
  final ValueChanged<NotificationPrefs> onChanged;

  static const _inactiveDaysOptions = [3, 5, 7, 10, 14];

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Notificações',
      children: [
        _ToggleRow(
          label: 'Novo lead qualificado',
          subtitle: 'Notificar quando score ≥ 60%',
          value: prefs.qualifiedLeads,
          onChanged: (v) =>
              onChanged(prefs.copyWith(qualifiedLeads: v)),
        ),
        const Divider(height: 1),
        _ToggleRow(
          label: 'Agendamento confirmado',
          subtitle: 'Notificar quando consultor é agendado',
          value: prefs.schedulingConfirmed,
          onChanged: (v) =>
              onChanged(prefs.copyWith(schedulingConfirmed: v)),
        ),
        const Divider(height: 1),
        _ToggleRow(
          label: 'Lead inativo',
          subtitle: 'Alertar após dias sem resposta',
          value: prefs.inactiveLeadDays != null,
          onChanged: (v) => onChanged(
            v
                ? prefs.copyWith(inactiveLeadDays: 7)
                : prefs.copyWith(clearInactiveDays: true),
          ),
          trailing: prefs.inactiveLeadDays != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: ShadSelect<int>(
                    minWidth: 80,
                    placeholder: Text(
                      '${prefs.inactiveLeadDays} dias',
                      style: AppTextStyles.bodySmall,
                    ),
                    options: _inactiveDaysOptions
                        .map((d) => ShadOption(value: d, child: Text('$d dias')))
                        .toList(),
                    selectedOptionBuilder: (ctx, v) =>
                        Text('$v dias', style: AppTextStyles.bodySmall),
                    onChanged: (v) {
                      if (v != null) {
                        onChanged(prefs.copyWith(inactiveLeadDays: v));
                      }
                    },
                  ),
                )
              : null,
        ),
        const Divider(height: 1),
        _ToggleRow(
          label: 'Novo lead recebido',
          subtitle: 'Notificar ao receber mensagem WhatsApp',
          value: prefs.newLeads,
          onChanged: (v) => onChanged(prefs.copyWith(newLeads: v)),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.trailing,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall
                    .copyWith(color: context.cadife.textSecondary),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          trailing!,
          const SizedBox(width: 8),
        ],
        ShadSwitch(value: value, onChanged: onChanged),
      ],
    );
  }
}

// ── Office Hours Section ──────────────────────────────────────────────────────

class _OfficeHoursSection extends StatelessWidget {
  const _OfficeHoursSection({
    required this.hours,
    required this.onChanged,
  });

  final List<OfficeHours> hours;
  final ValueChanged<List<OfficeHours>> onChanged;

  void _updateDay(OfficeHours updated) {
    final newHours = hours.map((h) => h.weekday == updated.weekday ? updated : h).toList();
    onChanged(newHours);
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Horários (Seg–Sex)',
      children: [
        ...hours.asMap().entries.map((e) {
          final i = e.key;
          final h = e.value;
          return Column(
            children: [
              _DayRow(
                hours: h,
                onToggle: (v) => _updateDay(h.copyWith(isOpen: v)),
                onTimeChanged: (open, close) =>
                    _updateDay(h.copyWith(openTime: open, closeTime: close)),
              ),
              if (i < hours.length - 1)
                const Divider(height: 1),
            ],
          );
        }),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.hours,
    required this.onToggle,
    required this.onTimeChanged,
  });

  final OfficeHours hours;
  final ValueChanged<bool> onToggle;
  final void Function(String open, String close) onTimeChanged;

  Future<void> _pickTime(BuildContext context, bool isOpen) async {
    final parts =
        (isOpen ? hours.openTime : hours.closeTime).split(':');
    final initial = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !context.mounted) return;
    final fmt =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    onTimeChanged(
      isOpen ? fmt : hours.openTime,
      isOpen ? hours.closeTime : fmt,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(hours.weekdayLabel, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          ),
          ShadSwitch(value: hours.isOpen, onChanged: onToggle),
          const Spacer(),
          if (hours.isOpen) ...[
            GestureDetector(
              onTap: () => _pickTime(context, true),
              child: _TimeChip(time: hours.openTime),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text('–',
                  style: TextStyle(color: context.cadife.textSecondary)),
            ),
            GestureDetector(
              onTap: () => _pickTime(context, false),
              child: _TimeChip(time: hours.closeTime),
            ),
          ] else
            Text(
              'Fechado',
              style: AppTextStyles.bodySmall
                  .copyWith(color: context.cadife.textSecondary),
            ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.time});
  final String time;

  @override
  Widget build(BuildContext context) {
    return ShadBadge.secondary(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Text(time),
    );
  }
}

// ── Templates Section ─────────────────────────────────────────────────────────

class _TemplatesSection extends StatelessWidget {
  const _TemplatesSection({
    required this.templates,
    required this.onChanged,
  });

  final List<MessageTemplate> templates;
  final ValueChanged<List<MessageTemplate>> onChanged;

  static const _maxTemplates = 5;

  String _newId() => 'tpl-${DateTime.now().millisecondsSinceEpoch}';

  Future<void> _openForm(
    BuildContext context, {
    MessageTemplate? existing,
  }) async {
    final result = await showShadDialog<MessageTemplate?>(
      context: context,
      builder: (ctx) => _TemplateFormDialog(template: existing),
    );
    if (result == null || !context.mounted) return;

    if (existing != null) {
      onChanged(templates.map((t) => t.id == existing.id ? result : t).toList());
    } else {
      onChanged([...templates, result]);
    }
  }

  Future<void> _duplicate(BuildContext context, MessageTemplate t) async {
    if (templates.length >= _maxTemplates) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Máximo de 5 templates atingido'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final copy = MessageTemplate(
      id: _newId(),
      title: '(cópia) ${t.title}',
      body: t.body,
    );
    // Open form pre-filled with the copy so user can edit before saving
    final result = await showShadDialog<MessageTemplate?>(
      context: context,
      builder: (ctx) => _TemplateFormDialog(template: copy),
    );
    if (result == null || !context.mounted) return;
    onChanged([...templates, result]);
  }

  Future<void> _delete(BuildContext context, MessageTemplate t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deletar template?'),
        content: Text('O template "${t.title}" será removido.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deletar',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      onChanged(templates.where((tmpl) => tmpl.id != t.id).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = templates.length < _maxTemplates;

    return _SectionCard(
      title: 'Templates de Resposta',
      children: [
        if (templates.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Nenhum template criado',
              style: AppTextStyles.bodySmall
                  .copyWith(color: context.cadife.textSecondary),
            ),
          )
        else
          ...templates.map((t) => Column(
                children: [
                  _TemplateCard(
                    template: t,
                    onEdit: () => _openForm(context, existing: t),
                    onDuplicate: () => _duplicate(context, t),
                    onDelete: () => _delete(context, t),
                  ),
                  const Divider(height: 1),
                ],
              )),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: ShadButton.outline(
            onPressed: canAdd ? () => _openForm(context) : null,
            leading: const Icon(Icons.add, size: 18),
            width: double.infinity,
            child: Text(canAdd
                ? 'Adicionar template'
                : 'Limite atingido ($_maxTemplates/$_maxTemplates)'),
          ),
        ),
      ],
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  final MessageTemplate template;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(template.title, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  template.body,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: context.cadife.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: context.cadife.textSecondary,
                tooltip: 'Editar',
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy_outlined, size: 18),
                color: context.cadife.textSecondary,
                tooltip: 'Duplicar',
                onPressed: onDuplicate,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppColors.error,
                tooltip: 'Deletar',
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Template Form Dialog ──────────────────────────────────────────────────────

class _TemplateFormDialog extends StatefulWidget {
  const _TemplateFormDialog({this.template});

  /// null = add mode; non-null = edit mode
  final MessageTemplate? template;

  @override
  State<_TemplateFormDialog> createState() => _TemplateFormDialogState();
}

class _TemplateFormDialogState extends State<_TemplateFormDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;

  bool get _isValid =>
      _titleCtrl.text.trim().isNotEmpty && _bodyCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.template?.title ?? '');
    _bodyCtrl = TextEditingController(text: widget.template?.body ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_isValid) return;
    final result = MessageTemplate(
      id: widget.template?.id ??
          'tpl-${DateTime.now().millisecondsSinceEpoch}',
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.template != null;
    return ShadDialog(
      title: Text(isEdit ? 'Editar Template' : 'Novo Template'),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancelar'),
        ),
        ShadButton(
          onPressed: _isValid ? _submit : null,
          child: Text(isEdit ? 'Salvar' : 'Adicionar'),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShadInput(
            controller: _titleCtrl,
            placeholder: const Text('Título (máx. 50 caracteres)'),
            maxLength: 50,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          ShadInput(
            controller: _bodyCtrl,
            placeholder: const Text('Mensagem (máx. 500 caracteres)'),
            maxLength: 500,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 4),
          Text(
            '${_bodyCtrl.text.length}/500 caracteres',
            style: AppTextStyles.caption
                .copyWith(color: context.cadife.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Security Section ──────────────────────────────────────────────────────────

class _SecuritySection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SectionCard(
      title: 'Segurança',
      children: [
        _ActionRow(
          icon: Icons.key_rounded,
          label: 'Alterar senha',
          subtitle: 'Requer verificação por email',
          onTap: () => _onChangePassword(context),
        ),
        const Divider(height: 1),
        _ActionRow(
          icon: Icons.logout_rounded,
          label: 'Sair de todos os dispositivos',
          subtitle: 'Revoga todas as sessões ativas',
          onTap: () => _onLogoutAll(context, ref),
          isDestructive: true,
        ),
      ],
    );
  }

  Future<void> _onChangePassword(BuildContext context) async {
    await showShadDialog<void>(
      context: context,
      builder: (ctx) => const _ChangePasswordDialog(),
    );
  }

  Future<void> _onLogoutAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair de todos os dispositivos?'),
        content: const Text(
          'Você será desconectado de todos os seus dispositivos e precisará fazer login novamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Best-effort: revoke server-side tokens; proceed even if request fails
    try {
      final dio = ref.read(dioClientProvider);
      await dio.post('/auth/logout-all-devices');
    } on Exception catch (_) {}

    if (!context.mounted) return;
    context.go('/auth/login');
  }
}

// ── Change Password Dialog ────────────────────────────────────────────────────

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;
  String? _error;

  bool get _newPasswordValid => _newCtrl.text.length >= 8;
  bool get _passwordsMatch =>
      _newCtrl.text == _confirmCtrl.text && _confirmCtrl.text.isNotEmpty;
  bool get _isValid =>
      _currentCtrl.text.isNotEmpty && _newPasswordValid && _passwordsMatch;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_isValid) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.changePassword(_currentCtrl.text, _newCtrl.text);

      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _error = failure.message;
          });
        },
        (_) {
          setState(() {
            _isLoading = false;
            _emailSent = true;
          });
        },
      );
    } on Exception catch (_) {
      setState(() {
        _isLoading = false;
        _error = 'Erro ao enviar solicitação. Tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_emailSent) {
      return ShadDialog(
        title: const Text('Verifique seu email'),
        description: const Text(
          'Enviamos um link de confirmação para o seu email cadastrado. Clique no link para confirmar a nova senha.',
        ),
        actions: [
          ShadButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
        child: const SizedBox.shrink(),
      );
    }

    return ShadDialog(
      title: const Text('Alterar Senha'),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ShadButton(
          onPressed: (_isValid && !_isLoading) ? _submit : null,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Enviar'),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShadInput(
            controller: _currentCtrl,
            placeholder: const Text('Senha atual'),
            obscureText: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          ShadInput(
            controller: _newCtrl,
            placeholder: const Text('Nova senha (mín. 8 caracteres)'),
            obscureText: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 4),
          _PasswordRequirements(password: _newCtrl.text),
          const SizedBox(height: 12),
          ShadInput(
            controller: _confirmCtrl,
            placeholder: const Text('Confirmar nova senha'),
            obscureText: true,
            onChanged: (_) => setState(() {}),
          ),
          if (_confirmCtrl.text.isNotEmpty && !_passwordsMatch) ...[
            const SizedBox(height: 4),
            Text(
              'Senhas não conferem',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.error),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _PasswordRequirements extends StatelessWidget {
  const _PasswordRequirements({required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        _Req(label: 'Mínimo 8 caracteres', met: password.length >= 8),
        _Req(
          label: 'Pelo menos 1 maiúscula',
          met: password.contains(RegExp(r'[A-Z]')),
        ),
        _Req(
          label: 'Pelo menos 1 número',
          met: password.contains(RegExp(r'[0-9]')),
        ),
      ],
    );
  }
}

class _Req extends StatelessWidget {
  const _Req({required this.label, required this.met});
  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 14,
            color: met ? AppColors.success : context.cadife.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: met ? AppColors.success : context.cadife.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDestructive
                    ? AppColors.error.withValues(alpha: 0.1)
                    : context.cadife.textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDestructive ? AppColors.error : context.cadife.textSecondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? AppColors.error : context.cadife.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(color: context.cadife.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: context.cadife.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Theme Section ─────────────────────────────────────────────────────────────

class _ThemeSection extends ConsumerWidget {
  const _ThemeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePref = ref.watch(themeNotifierProvider);

    return _SectionCard(
      title: 'Aparência',
      children: [
        themePref.maybeWhen(
          data: (pref) => Column(
            children: [
              _ThemeOptionRow(
                label: 'Tema Claro',
                subtitle: 'Ideal para ambientes bem iluminados',
                icon: Icons.light_mode_rounded,
                value: pref == ThemePreference.light,
                onChanged: (v) {
                  if (v) ref.read(themeNotifierProvider.notifier).setTheme(ThemePreference.light);
                },
              ),
              const Divider(height: 1),
              _ThemeOptionRow(
                label: 'Tema Escuro',
                subtitle: 'Reduz o cansaço visual e economiza bateria',
                icon: Icons.dark_mode_rounded,
                value: pref == ThemePreference.dark,
                onChanged: (v) {
                  if (v) ref.read(themeNotifierProvider.notifier).setTheme(ThemePreference.dark);
                },
              ),
              const Divider(height: 1),
              _ThemeOptionRow(
                label: 'Padrão do Sistema',
                subtitle: 'Sincroniza com as configurações do dispositivo',
                icon: Icons.settings_brightness_rounded,
                value: pref == ThemePreference.system,
                onChanged: (v) {
                  if (v) ref.read(themeNotifierProvider.notifier).setTheme(ThemePreference.system);
                },
              ),
            ],
          ),
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _ThemeOptionRow extends StatelessWidget {
  const _ThemeOptionRow({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: value
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : context.cadife.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: value ? AppColors.primary : context.cadife.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: value ? AppColors.primary : context.cadife.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(color: context.cadife.textSecondary),
                ),
              ],
            ),
          ),
          ShadSwitch(
            value: value,
            onChanged: (v) {
              if (v) {
                onChanged(v);
              }
            },
          ),
        ],
      ),
    );
  }
}

