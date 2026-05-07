import 'dart:async';

import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cadife_smart_travel/features/client/settings/domain/entities/client_settings.dart';
import 'package:cadife_smart_travel/features/client/settings/infrastructure/mocks/client_settings_mocks.dart';
import 'package:cadife_smart_travel/features/settings/application/theme_notifier.dart';
import 'package:cadife_smart_travel/features/settings/domain/entities/user_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

// ---------------------------------------------------------------------------
// Public entry-point (referenced by GoRouter)
// ---------------------------------------------------------------------------

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late ClientSettings _settings;
  bool _isSaving = false;
  bool _personalDataValid = true;

  @override
  void initState() {
    super.initState();
    _settings = ClientSettingsMocks.mockSettings();
  }

  Future<void> _save() async {
    if (!_personalDataValid) return;
    setState(() => _isSaving = true);

    try {
      // Tarefa pendente: PATCH /users/me with _settings
      await Future.delayed(const Duration(milliseconds: 900));

      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(description: Text('Configurações salvas com sucesso')),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(description: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: cadife.background,
      appBar: AppBar(
        backgroundColor: cadife.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: cadife.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Configurações',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: cadife.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SettingsSection(
            title: 'Meus Dados',
            icon: LucideIcons.user,
            child: _PersonalDataSection(
              settings: _settings,
              onChanged: (updated, {required isValid}) {
                setState(() {
                  _settings = updated;
                  _personalDataValid = isValid;
                });
              },
            ),
          ),
          const SizedBox(height: 20),
          _SettingsSection(
            title: 'Notificações',
            icon: LucideIcons.bell,
            child: _NotificationsSection(
              settings: _settings,
              onChanged: (updated) => setState(() => _settings = updated),
            ),
          ),
          const SizedBox(height: 20),
          const _SettingsSection(
            title: 'Aparência',
            icon: LucideIcons.palette,
            child: _ThemeSection(),
          ),
          const SizedBox(height: 20),
          _SettingsSection(
            title: 'Segurança',
            icon: LucideIcons.shield,
            child: _SecuritySection(ref: ref),
          ),
          const SizedBox(height: 20),
          _SettingsSection(
            title: 'Conta',
            icon: LucideIcons.settings,
            child: _AccountSection(ref: ref),
          ),
          const SizedBox(height: 20),
          _SettingsSection(
            title: 'Idioma',
            icon: LucideIcons.languages,
            child: _LanguageSection(),
          ),
          const SizedBox(height: 20),
          _SettingsSection(
            title: 'Suporte e Legal',
            icon: LucideIcons.lifeBuoy,
            child: const _SupportSection(),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: (_isSaving || !_personalDataValid) ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(LucideIcons.save, size: 18),
              label: Text(
                _isSaving ? 'Salvando...' : 'Salvar Alterações',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section wrapper
// ---------------------------------------------------------------------------

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: cadife.textSecondary),
            const SizedBox(width: 6),
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: cadife.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ShadCard(
          padding: const EdgeInsets.all(16),
          backgroundColor: cadife.cardBackground,
          border: ShadBorder.all(color: cadife.cardBorder, width: 1),
          radius: BorderRadius.circular(16),
          child: child,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 1 — Personal Data
// ---------------------------------------------------------------------------

class _PersonalDataSection extends StatefulWidget {
  const _PersonalDataSection({
    required this.settings,
    required this.onChanged,
  });

  final ClientSettings settings;
  final void Function(ClientSettings updated, {required bool isValid}) onChanged;

  @override
  State<_PersonalDataSection> createState() => _PersonalDataSectionState();
}

class _PersonalDataSectionState extends State<_PersonalDataSection> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _dobCtrl;

  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _dobError;

  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.settings.name);
    _emailCtrl = TextEditingController(text: widget.settings.email);
    _phoneCtrl = TextEditingController(
      text: _phoneMask.maskText(widget.settings.phone),
    );
    _dobCtrl = TextEditingController(
      text: widget.settings.dateOfBirth != null
          ? _formatDateBr(widget.settings.dateOfBirth!)
          : '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  String _formatDateBr(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  DateTime? _parseDateBr(String s) {
    final parts = s.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime(year, month, day);
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String? _validateName(String v) {
    if (v.trim().isEmpty) return 'Nome é obrigatório';
    if (v.trim().length < 2) return 'Mínimo de 2 caracteres';
    return null;
  }

  String? _validateEmail(String v) {
    if (v.trim().isEmpty) return 'E-mail é obrigatório';
    final re = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!re.hasMatch(v.trim())) return 'E-mail inválido';
    return null;
  }

  String? _validatePhone(String v) {
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Telefone é obrigatório';
    if (digits.length < 10) return 'Telefone incompleto';
    return null;
  }

  String? _validateDob(String v) {
    if (v.isEmpty) return null;
    final date = _parseDateBr(v);
    if (date == null) return 'Data inválida (DD/MM/AAAA)';
    if (date.isAfter(DateTime.now())) return 'Data não pode ser no futuro';
    if (DateTime.now().year - date.year < 13) return 'Idade mínima: 13 anos';
    return null;
  }

  bool get _isValid =>
      _nameError == null &&
      _emailError == null &&
      _phoneError == null &&
      _dobError == null;

  void _notify() {
    final rawPhone = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    final dob = _dobCtrl.text.isNotEmpty ? _parseDateBr(_dobCtrl.text) : null;

    final updated = widget.settings.copyWith(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: rawPhone,
      dateOfBirth: dob,
      clearDateOfBirth: _dobCtrl.text.isEmpty,
    );
    widget.onChanged(updated, isValid: _isValid);
  }

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;

    return Column(
      children: [
        const SizedBox(height: 8),
        Center(
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    width: 2,
                  ),
                ),
                child: ShadAvatar(
                  widget.settings.avatarUrl ?? '',
                  size: const Size.square(110),
                  placeholder: Text(
                    _initials(widget.settings.name),
                    style: GoogleFonts.inter(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    ShadToaster.of(context).show(
                      const ShadToast(
                        description: Text('Funcionalidade de upload em breve'),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                      border: Border.all(
                        color: cadife.cardBackground,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.camera,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        CadifeInput(
          label: 'Nome Completo',
          controller: _nameCtrl,
          keyboardType: TextInputType.name,
          errorText: _nameError,
          onChanged: (v) {
            setState(() => _nameError = _validateName(v));
            _notify();
          },
        ),
        const SizedBox(height: 14),
        CadifeInput(
          label: 'E-mail',
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          errorText: _emailError,
          onChanged: (v) {
            setState(() => _emailError = _validateEmail(v));
            _notify();
          },
        ),
        const SizedBox(height: 14),
        _PhoneCadifeField(
          controller: _phoneCtrl,
          phoneMask: _phoneMask,
          errorText: _phoneError,
          onChanged: (v) {
            setState(() => _phoneError = _validatePhone(v));
            _notify();
          },
        ),
        const SizedBox(height: 14),
        _DobCadifeField(
          controller: _dobCtrl,
          errorText: _dobError,
          onChanged: (v) {
            setState(() => _dobError = _validateDob(v));
            _notify();
          },
        ),
      ],
    );
  }
}

// Phone field uses mask formatter — thin wrapper over raw TextFormField
// styled to match CadifeInput visually.
class _PhoneCadifeField extends StatefulWidget {
  const _PhoneCadifeField({
    required this.controller,
    required this.phoneMask,
    required this.errorText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final MaskTextInputFormatter phoneMask;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  State<_PhoneCadifeField> createState() => _PhoneCadifeFieldState();
}

class _PhoneCadifeFieldState extends State<_PhoneCadifeField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Telefone',
            style: GoogleFonts.inter(
              color: cadife.textPrimary.withValues(alpha: 0.8),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Focus(
          onFocusChange: (v) => setState(() => _focused = v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: cadife.muted.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.errorText != null
                    ? cadife.primary
                    : _focused
                        ? cadife.primary
                        : cadife.cardBorder,
                width: 1.5,
              ),
            ),
            child: TextFormField(
              controller: widget.controller,
              keyboardType: TextInputType.phone,
              inputFormatters: [widget.phoneMask],
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              style: GoogleFonts.inter(color: cadife.textPrimary, fontSize: 15),
              decoration: const InputDecoration(
                hintText: '(11) 99999-9999',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: widget.onChanged,
            ),
          ),
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              widget.errorText!,
              style: GoogleFonts.inter(
                color: cadife.primary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

// Date of birth field with DD/MM/AAAA mask
class _DobCadifeField extends StatefulWidget {
  const _DobCadifeField({
    required this.controller,
    required this.errorText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  State<_DobCadifeField> createState() => _DobCadifeFieldState();
}

class _DobCadifeFieldState extends State<_DobCadifeField> {
  bool _focused = false;
  final _dateMask = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Data de Nascimento (opcional)',
            style: GoogleFonts.inter(
              color: cadife.textPrimary.withValues(alpha: 0.8),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Focus(
          onFocusChange: (v) => setState(() => _focused = v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: cadife.muted.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.errorText != null
                    ? cadife.primary
                    : _focused
                        ? cadife.primary
                        : cadife.cardBorder,
                width: 1.5,
              ),
            ),
            child: TextFormField(
              controller: widget.controller,
              keyboardType: TextInputType.datetime,
              inputFormatters: [_dateMask],
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              style: GoogleFonts.inter(color: cadife.textPrimary, fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'DD/MM/AAAA',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: widget.onChanged,
            ),
          ),
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              widget.errorText!,
              style: GoogleFonts.inter(
                color: cadife.primary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 2 — Notifications
// ---------------------------------------------------------------------------

class _NotificationsSection extends StatefulWidget {
  const _NotificationsSection({
    required this.settings,
    required this.onChanged,
  });

  final ClientSettings settings;
  final ValueChanged<ClientSettings> onChanged;

  @override
  State<_NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<_NotificationsSection> {
  late ClientSettings _s;

  @override
  void initState() {
    super.initState();
    _s = widget.settings;
  }

  void _update(ClientSettings s) {
    setState(() => _s = s);
    widget.onChanged(s);
  }

  Future<void> _pickTime(
    BuildContext ctx,
    String current,
    ValueChanged<String> onPicked,
  ) async {
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    final picked = await showTimePicker(context: ctx, initialTime: initial);
    if (picked != null) {
      onPicked(
        '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SubSectionLabel(label: 'Push', cadife: cadife, theme: theme),
        const SizedBox(height: 4),
        _NotifToggle(
          title: 'Ofertas da Agência',
          subtitle: 'Novidades e promoções exclusivas',
          value: _s.notificationsPushOffers,
          onChanged: (v) =>
              _update(_s.copyWith(notificationsPushOffers: v)),
        ),
        _NotifToggle(
          title: 'Atualizações da Minha Viagem',
          subtitle: 'Mudanças em reservas e roteiros',
          value: _s.notificationsPushTripsUpdates,
          onChanged: (v) =>
              _update(_s.copyWith(notificationsPushTripsUpdates: v)),
        ),
        _NotifToggle(
          title: 'Mensagens da AYA',
          subtitle: 'Respostas do assistente de IA',
          value: _s.notificationsPushAya,
          onChanged: (v) =>
              _update(_s.copyWith(notificationsPushAya: v)),
        ),
        const SizedBox(height: 16),
        Divider(color: cadife.divider, height: 1),
        const SizedBox(height: 16),
        _SubSectionLabel(label: 'In-App', cadife: cadife, theme: theme),
        const SizedBox(height: 4),
        _NotifToggle(
          title: 'Ofertas da Agência',
          subtitle: 'Notificações dentro do app',
          value: _s.notificationsInAppOffers,
          onChanged: (v) =>
              _update(_s.copyWith(notificationsInAppOffers: v)),
        ),
        _NotifToggle(
          title: 'Atualizações da Minha Viagem',
          subtitle: 'Notificações dentro do app',
          value: _s.notificationsInAppTripsUpdates,
          onChanged: (v) =>
              _update(_s.copyWith(notificationsInAppTripsUpdates: v)),
        ),
        _NotifToggle(
          title: 'Mensagens da AYA',
          subtitle: 'Notificações dentro do app',
          value: _s.notificationsInAppAya,
          onChanged: (v) =>
              _update(_s.copyWith(notificationsInAppAya: v)),
        ),
        const SizedBox(height: 16),
        Divider(color: cadife.divider, height: 1),
        const SizedBox(height: 16),
        _SubSectionLabel(label: 'Não Perturbe', cadife: cadife, theme: theme),
        const SizedBox(height: 4),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          activeTrackColor: AppColors.primary,
          title: Text(
            'Silenciar notificações',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cadife.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'Bloqueia push em horário específico',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cadife.textSecondary,
            ),
          ),
          value: _s.dndEnabled,
          onChanged: (v) => _update(_s.copyWith(dndEnabled: v)),
        ),
        if (_s.dndEnabled) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TimePickerTile(
                  label: 'Início',
                  time: _s.dndStartTime,
                  cadife: cadife,
                  theme: theme,
                  onTap: () => _pickTime(
                    context,
                    _s.dndStartTime,
                    (t) => _update(_s.copyWith(dndStartTime: t)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimePickerTile(
                  label: 'Fim',
                  time: _s.dndEndTime,
                  cadife: cadife,
                  theme: theme,
                  onTap: () => _pickTime(
                    context,
                    _s.dndEndTime,
                    (t) => _update(_s.copyWith(dndEndTime: t)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SubSectionLabel extends StatelessWidget {
  const _SubSectionLabel({
    required this.label,
    required this.cadife,
    required this.theme,
  });

  final String label;
  final CadifeThemeExtension cadife;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: cadife.textSecondary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _NotifToggle extends StatelessWidget {
  const _NotifToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final theme = Theme.of(context);

    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      activeTrackColor: AppColors.primary,
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: cadife.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: cadife.textSecondary,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  const _TimePickerTile({
    required this.label,
    required this.time,
    required this.cadife,
    required this.theme,
    required this.onTap,
  });

  final String label;
  final String time;
  final CadifeThemeExtension cadife;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cadife.muted.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cadife.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: cadife.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: GoogleFonts.inter(
                color: cadife.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3 — Theme
// ---------------------------------------------------------------------------

class _ThemeSection extends ConsumerWidget {
  const _ThemeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePref = ref.watch(themeNotifierProvider).maybeWhen(
          data: (p) => p,
          orElse: () => ThemePreference.system,
        );

    return Column(
      children: [
        _ThemeOption(
          icon: LucideIcons.sun,
          title: 'Claro',
          isSelected: themePref == ThemePreference.light,
          onTap: () => ref
              .read(themeNotifierProvider.notifier)
              .setTheme(ThemePreference.light),
        ),
        const SizedBox(height: 10),
        _ThemeOption(
          icon: LucideIcons.moon,
          title: 'Escuro',
          isSelected: themePref == ThemePreference.dark,
          onTap: () => ref
              .read(themeNotifierProvider.notifier)
              .setTheme(ThemePreference.dark),
        ),
        const SizedBox(height: 10),
        _ThemeOption(
          icon: LucideIcons.monitor,
          title: 'Sistema',
          isSelected: themePref == ThemePreference.system,
          onTap: () => ref
              .read(themeNotifierProvider.notifier)
              .setTheme(ThemePreference.system),
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : cadife.muted.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : cadife.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primary : cadife.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected ? AppColors.primary : cadife.textPrimary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              const Icon(LucideIcons.check, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4 — Security
// ---------------------------------------------------------------------------

class _SecuritySection extends StatelessWidget {
  const _SecuritySection({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final theme = Theme.of(context);

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(LucideIcons.keyRound, color: cadife.textSecondary, size: 20),
          title: Text(
            'Alterar Senha',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cadife.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'Redefinir via e-mail',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cadife.textSecondary,
            ),
          ),
          trailing: Icon(LucideIcons.chevronRight,
              size: 16, color: cadife.textSecondary),
          onTap: () {
            ShadToaster.of(context).show(
              const ShadToast(
                description: Text('Link de redefinição enviado para seu e-mail'),
              ),
            );
          },
        ),
        Divider(color: cadife.divider, height: 1),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(LucideIcons.shieldCheck, color: cadife.textSecondary, size: 20),
          title: Text(
            'Segurança',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cadife.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'Autenticação e privacidade',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cadife.textSecondary,
            ),
          ),
          trailing: Icon(LucideIcons.chevronRight,
              size: 16, color: cadife.textSecondary),
          onTap: () {},
        ),
        Divider(color: cadife.divider, height: 1),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(LucideIcons.logOut, color: cadife.textSecondary, size: 20),
          title: Text(
            'Sair desta Conta',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cadife.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'Encerrar sessão neste dispositivo',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cadife.textSecondary,
            ),
          ),
          trailing: Icon(LucideIcons.chevronRight,
              size: 16, color: cadife.textSecondary),
          onTap: () => _confirmLogout(context, ref),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 5 — Account (delete)
// ---------------------------------------------------------------------------

class _AccountSection extends StatelessWidget {
  const _AccountSection({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(LucideIcons.trash2, color: AppColors.error, size: 20),
      title: Text(
        'Excluir Conta',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: Text(
        'Apagar permanentemente seus dados',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.error.withValues(alpha: 0.7),
            ),
      ),
      trailing:
          const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.error),
      onTap: () => _showDeleteStep1(context, ref),
    );
  }
}

// ---------------------------------------------------------------------------
// Logout dialog
// ---------------------------------------------------------------------------

Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
  final confirmed = await showShadDialog<bool>(
    context: context,
    builder: (ctx) => ShadDialog(
      title: const Text('Sair da conta'),
      description: const Text(
        'Tem certeza que deseja encerrar a sessão neste dispositivo?',
      ),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancelar'),
        ),
        ShadButton.destructive(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Sair'),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    await ref.read(authNotifierProvider.notifier).logout();
  }
}

// ---------------------------------------------------------------------------
// Delete account — step 1: warn
// ---------------------------------------------------------------------------

void _showDeleteStep1(BuildContext context, WidgetRef ref) {
  showShadDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => ShadDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
          SizedBox(width: 8),
          Text('Excluir conta?'),
        ],
      ),
      description: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Você está prestes a excluir permanentemente sua conta e todos os dados associados.',
          ),
          SizedBox(height: 10),
          Text(
            'Esta ação não pode ser desfeita.',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.error,
            ),
          ),
        ],
      ),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancelar'),
        ),
        ShadButton.destructive(
          onPressed: () {
            Navigator.of(ctx).pop();
            if (context.mounted) _showDeleteStep2(context, ref);
          },
          child: const Text('Continuar'),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Delete account — step 2: type "EXCLUIR"
// ---------------------------------------------------------------------------

void _showDeleteStep2(BuildContext context, WidgetRef ref) {
  final ctrl = TextEditingController();

  showShadDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        final isValid = ctrl.text == 'EXCLUIR';

        return ShadDialog(
          title: const Text('Confirmação final'),
          description: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Digite EXCLUIR para confirmar:'),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                autofocus: true,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setDialogState(() {}),
                decoration: InputDecoration(
                  hintText: 'EXCLUIR',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ],
          ),
          actions: [
            ShadButton.outline(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ShadButton.destructive(
              onPressed: isValid
                  ? () {
                      Navigator.of(ctx).pop();
                      if (context.mounted) {
                        _executeDeleteAccount(context, ref);
                      }
                    }
                  : null,
              child: const Text('Excluir Permanentemente'),
            ),
          ],
        );
      },
    ),
  );
}

// ---------------------------------------------------------------------------
// Delete account — step 3: execute
// ---------------------------------------------------------------------------

Future<void> _executeDeleteAccount(BuildContext context, WidgetRef ref) async {
  // Show loading overlay
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ColoredBox(
        color: Colors.transparent,
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
    ),
  );

  try {
    // Tarefa pendente: DELETE /users/me + clear local Isar data
    await Future.delayed(const Duration(seconds: 2));

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
      await ref.read(authNotifierProvider.notifier).logout();
    }
  } on Exception catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ShadToaster.of(context).show(
        ShadToast.destructive(description: Text('Erro ao excluir: $e')),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// 6 — Language
// ---------------------------------------------------------------------------

class _LanguageSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(LucideIcons.languages, color: cadife.textSecondary, size: 20),
      title: Text(
        'Idioma',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: cadife.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        'Português (Brasil)',
        style: theme.textTheme.bodySmall?.copyWith(
          color: cadife.textSecondary,
        ),
      ),
      trailing: Icon(LucideIcons.chevronRight,
          size: 16, color: cadife.textSecondary),
      onTap: () {},
    );
  }
}

// ---------------------------------------------------------------------------
// 7 — Support
// ---------------------------------------------------------------------------

class _SupportSection extends StatelessWidget {
  const _SupportSection();

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final theme = Theme.of(context);

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(LucideIcons.lifeBuoy, color: cadife.textSecondary, size: 20),
          title: Text(
            'Central de Ajuda',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cadife.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Icon(LucideIcons.chevronRight,
              size: 16, color: cadife.textSecondary),
          onTap: () {},
        ),
        Divider(color: cadife.divider, height: 1),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(LucideIcons.fileText, color: cadife.textSecondary, size: 20),
          title: Text(
            'Termos e Privacidade',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cadife.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Icon(LucideIcons.chevronRight,
              size: 16, color: cadife.textSecondary),
          onTap: () {},
        ),
      ],
    );
  }
}

