import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cadife_smart_travel/features/client/profile/presentation/widgets/profile_widgets.dart';
import 'package:cadife_smart_travel/features/settings/application/theme_notifier.dart';
import 'package:cadife_smart_travel/features/settings/domain/entities/user_preferences.dart';
import 'package:cadife_smart_travel/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notifInApp = true;
  bool _notifPush = true;
  bool _notifNewLead = true;
  bool _notifNewMeeting = true;
  bool _notifAutoDeactivate = false;
  TimeOfDay _deactivateTime = const TimeOfDay(hour: 22, minute: 0);

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final cadife = context.cadife;
    // final isDark = context.isDark; // Removido por nÃ£o ser usado
    final themePref = ref.watch(themeNotifierProvider).maybeWhen(
          data: (p) => p,
          orElse: () => ThemePreference.system,
        );

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return Scaffold(
            backgroundColor: cadife.background,
            body: const Center(child: Text('Usuário não autenticado')),
          );
        }

        return Scaffold(
          backgroundColor: cadife.background,
          appBar: AppBar(
            title: Text(
              'CONFIGURAÇÕES',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 1.5,
                color: cadife.textPrimary,
              ),
            ),
            elevation: 0,
            centerTitle: true,
            backgroundColor: cadife.background,
            foregroundColor: cadife.textPrimary,
            leading: IconButton(
              icon: Icon(LucideIcons.chevronLeft, color: cadife.textPrimary),
              onPressed: () => context.pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SEÇÃO: Notificações
                _buildSection(
                  context,
                  title: 'NOTIFICAÇÕES',
                  children: [
                    _buildSettingToggle(
                      context,
                      label: 'Notificações In-app',
                      description: 'Receber avisos dentro do aplicativo',
                      value: _notifInApp,
                      onChanged: (value) => setState(() => _notifInApp = value),
                    ),
                    _buildSettingToggle(
                      context,
                      label: 'Notificações Push',
                      description: 'Receber notificações no sistema',
                      value: _notifPush,
                      onChanged: (value) => setState(() => _notifPush = value),
                    ),
                    if (user.role == UserRole.consultor) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _buildSettingToggle(
                        context,
                        label: 'Novo Lead',
                        description: 'Avisar quando chegar um novo lead',
                        value: _notifNewLead,
                        onChanged: (value) => setState(() => _notifNewLead = value),
                      ),
                      _buildSettingToggle(
                        context,
                        label: 'Nova Reunião',
                        description: 'Avisar quando uma reunião for marcada',
                        value: _notifNewMeeting,
                        onChanged: (value) => setState(() => _notifNewMeeting = value),
                      ),
                      _buildSettingToggle(
                        context,
                        label: 'Pausar Notificações',
                        description: 'Desativar notificações em horário específico',
                        value: _notifAutoDeactivate,
                        onChanged: (value) => setState(() => _notifAutoDeactivate = value),
                      ),
                      if (_notifAutoDeactivate)
                        _buildTimeInput(
                          context,
                          label: 'Horário para desativar',
                          time: _deactivateTime,
                          onChanged: (time) => setState(() => _deactivateTime = time),
                        ),
                    ],
                  ],
                ),


                // SEÇÃO: Aparência
                _buildSection(
                  context,
                  title: 'APARÊNCIA',
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ProfileThemeSelector(
                        themePreference: themePref,
                        onChanged: (pref) =>
                            ref.read(themeNotifierProvider.notifier).setTheme(pref),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // SEÇÃO: Segurança
                _buildSection(
                  context,
                  title: 'SEGURANÇA',
                  children: [
                    _buildSettingButton(
                      context,
                      label: 'Alterar Senha',
                      onTap: () => _showChangePasswordModal(context),
                    ),
                    _buildSettingButton(
                      context,
                      label: 'Sair de todos os dispositivos',
                      onTap: () => _showLogoutAllModal(context),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // SEÇÃO: Informações
                _buildSection(
                  context,
                  title: 'INFORMAÇÕES',
                  children: [
                    _buildInfoRow(context, label: 'Versão', value: '1.0.0'),
                    _buildInfoRow(context, label: 'Desenvolvedor', value: 'Cadife Smart Travel'),
                  ],
                ),

                const SizedBox(height: 32),

                // Ações da conta
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      CadifeButton(
                        text: 'Sair da conta',
                        icon: LucideIcons.logOut,
                        isOutline: true,
                        onPressed: () => _confirmLogout(context, ref),
                      ),
                      const SizedBox(height: 12),
                      CadifeButton(
                        text: 'Deletar conta',
                        icon: LucideIcons.trash2,
                        isOutline: true,
                        onPressed: () => _confirmDeleteAccount(context, ref),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: cadife.background,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        backgroundColor: cadife.background,
        body: Center(child: Text('Erro: $e')),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final cadife = context.cadife;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: cadife.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cadife.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cadife.cardBorder),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingToggle(
    BuildContext context, {
    required String label,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final cadife = context.cadife;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: cadife.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: cadife.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ShadSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInput(
    BuildContext context, {
    required String label,
    required TimeOfDay time,
    required ValueChanged<TimeOfDay> onChanged,
  }) {
    final cadife = context.cadife;
    return InkWell(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: cadife.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: cadife.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cadife.cardBorder),
              ),
              child: Text(
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildSettingButton(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    final cadife = context.cadife;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: cadife.textPrimary,
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16, color: cadife.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final cadife = context.cadife;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: cadife.textPrimary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cadife.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordModal(BuildContext context) {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Alterar Senha'),
        description: const Text('Digite sua senha atual e a nova senha desejada.'),
        actions: [
          Row(
            children: [
              Expanded(
                child: ShadButton.outline(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ShadButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ShadToaster.of(context).show(
                      const ShadToast(description: Text('Senha alterada com sucesso')),
                    );
                  },
                  child: const Text(
                    'Salvar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShadInput(
              placeholder: Text('Senha Atual'),
              obscureText: true,
              leading: Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(LucideIcons.lock, size: 16),
              ),
            ),
            SizedBox(height: 12),
            ShadInput(
              placeholder: Text('Nova Senha'),
              obscureText: true,
              leading: Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(LucideIcons.keyRound, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutAllModal(BuildContext context) {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Logout em Todos os Dispositivos'),
        description: const Text('Você será desconectado de todas as sessões ativas.'),
        actions: [
          Row(
            children: [
              Expanded(
                child: ShadButton.outline(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ShadButton.destructive(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _handleLogout(context);
                  },
                  child: const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    ref.read(authNotifierProvider.notifier).logout();
    ref.read(currentUserProvider.notifier).logout();
    context.go('/auth/login');
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (ctx) => ShadDialog(
        title: const Text('Sair da conta'),
        description: const Text('Tem certeza que deseja sair?'),
        actions: [
          Row(
            children: [
              Expanded(
                child: ShadButton.outline(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ShadButton.destructive(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Sair'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      _handleLogout(context);
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (ctx) => ShadDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.triangleAlert, color: AppColors.error, size: 20),
            SizedBox(width: 8),
            Text('Apagar conta'),
          ],
        ),
        description: const Text(
          'Esta ação é permanente e todos os seus dados serão perdidos. Tem certeza?',
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: ShadButton.outline(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ShadButton.destructive(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Apagar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ShadToaster.of(context).show(
        const ShadToast(description: Text('Solicitação de exclusão enviada')),
      );
    }
  }
}

