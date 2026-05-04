import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cadife_smart_travel/features/auth/presentation/bloc/auth_event.dart';
import 'package:cadife_smart_travel/features/client/profile/profile_provider.dart';
import 'package:cadife_smart_travel/features/client/profile/profile_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Tela de perfil do cliente.
///
/// Exibe dados pessoais (nome editÃƒÂ¡vel, email, telefone read-only),
/// preferÃƒÂªncias de viagem via chips (tipo_viagem, preferencias),
/// toggle de passaporte vÃƒÂ¡lido, controle de tema e logout.
///
/// Integra com GET /users/me e PATCH /users/me via [ProfilePort].
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;
  bool _hasSynced = false;

  final List<String> _tipoViagemSelected = [];
  final List<String> _preferenciasSelected = [];
  bool? _temPassaporte;

  static const _tipoViagemOptions = [
    'turismo',
    'lazer',
    'aventura',
    'imigraÃƒÂ§ÃƒÂ£o',
    'negÃƒÂ³cios',
  ];

  static const _preferenciasOptions = [
    'frio',
    'calor',
    'praia',
    'cidade',
    'luxo',
    'econÃƒÂ´mico',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _syncFromUser(AuthUser? user) {
    if (user == null || _hasSynced) return;
    _nameController.text = user.name;
    _tipoViagemSelected
      ..clear()
      ..addAll(user.tipoViagem ?? []);
    _preferenciasSelected
      ..clear()
      ..addAll(user.preferencias ?? []);
    _temPassaporte = user.temPassaporte;
    _hasSynced = true;
  }

  Future<void> _save(AuthUser? current) async {
    if (current == null || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(userProfileProvider.notifier).updateProfile(
            name: _nameController.text.trim(),
            tipoViagem: List<String>.from(_tipoViagemSelected),
            preferencias: List<String>.from(_preferenciasSelected),
            temPassaporte: _temPassaporte,
          );
      if (mounted) {
        setState(() {
          _isEditing = false;
          _hasSynced = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso')),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar. Tente novamente.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: userAsync.when(
          loading: () =>
              const AppLoadingWidget(message: 'Carregando perfil...'),
          error: (e, _) => AppErrorWidget(
            message: 'Erro ao carregar perfil. Tente novamente.',
            onRetry: () => ref.invalidate(userProfileProvider),
          ),
          data: (user) {
            if (!_isEditing) _syncFromUser(user);
            return _buildContent(context, user, themeMode, isDark);
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AuthUser? user,
    ThemeMode themeMode,
    bool isDark,
  ) {
    return CustomScrollView(
      slivers: [
        // Ã¢â€â‚¬Ã¢â€â‚¬ Header com avatar e nome Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
        SliverToBoxAdapter(
          child: ProfileHeader(
            user: user,
            isDark: isDark,
            isEditing: _isEditing,
            nameController: _nameController,
            onToggleEdit: () => setState(() => _isEditing = !_isEditing),
          ),
        ),

        // Ã¢â€â‚¬Ã¢â€â‚¬ Dados Pessoais Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
        SliverToBoxAdapter(
          child: ProfileSectionCard(
            title: 'Dados Pessoais',
            isDark: isDark,
            children: [
              ProfileInfoRow(
                icon: Icons.email_outlined,
                label: 'E-mail',
                value: user?.email ?? 'Ã¢â‚¬â€',
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              ProfileInfoRow(
                icon: Icons.phone_outlined,
                label: 'Telefone',
                value: user?.phone ?? 'NÃƒÂ£o informado',
                isDark: isDark,
                readOnly: true,
              ),
              const SizedBox(height: 16),
              ProfileInfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Membro desde',
                value: user?.createdAt != null
                    ? DateFormat('dd/MM/yyyy').format(user!.createdAt!)
                    : 'Ã¢â‚¬â€',
                isDark: isDark,
              ),
            ],
          ),
        ),

        // Ã¢â€â‚¬Ã¢â€â‚¬ PreferÃƒÂªncias de Viagem Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
        SliverToBoxAdapter(
          child: ProfileSectionCard(
            title: 'PreferÃƒÂªncias de Viagem',
            isDark: isDark,
            children: [
              ProfileChipGroup(
                label: 'Tipo de viagem',
                options: _tipoViagemOptions,
                selected: _tipoViagemSelected,
                isDark: isDark,
                onTap: _isEditing
                    ? (val) => setState(() {
                          if (_tipoViagemSelected.contains(val)) {
                            _tipoViagemSelected.remove(val);
                          } else {
                            _tipoViagemSelected.add(val);
                          }
                        })
                    : null,
              ),
              const SizedBox(height: 20),
              ProfileChipGroup(
                label: 'PreferÃƒÂªncias',
                options: _preferenciasOptions,
                selected: _preferenciasSelected,
                isDark: isDark,
                onTap: _isEditing
                    ? (val) => setState(() {
                          if (_preferenciasSelected.contains(val)) {
                            _preferenciasSelected.remove(val);
                          } else {
                            _preferenciasSelected.add(val);
                          }
                        })
                    : null,
              ),
            ],
          ),
        ),

        // Ã¢â€â‚¬Ã¢â€â‚¬ Passaporte Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
        SliverToBoxAdapter(
          child: ProfilePassaporteCard(
            value: _temPassaporte,
            isDark: isDark,
            onToggle: _isEditing
                ? () => setState(
                    () => _temPassaporte = !(_temPassaporte ?? false))
                : null,
          ),
        ),

        // Ã¢â€â‚¬Ã¢â€â‚¬ AparÃƒÂªncia (tema) Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
        SliverToBoxAdapter(
          child: ProfileSectionCard(
            title: 'AparÃƒÂªncia',
            isDark: isDark,
            children: [
              ProfileThemeSelector(
                themeMode: themeMode,
                onChanged: (mode) {
                  final notifier = ref.read(themeModeProvider.notifier);
                  switch (mode) {
                    case ThemeMode.system:
                      notifier.setSystem();
                    case ThemeMode.light:
                      notifier.setLight();
                    case ThemeMode.dark:
                      notifier.setDark();
                  }
                },
                isDark: isDark,
              ),
            ],
          ),
        ),

        // Ã¢â€â‚¬Ã¢â€â‚¬ AÃƒÂ§ÃƒÂµes (salvar / logout / apagar conta) Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                if (_isEditing) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : () => _save(user),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Salvar alteraÃƒÂ§ÃƒÂµes'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                          _hasSynced = false;
                          _syncFromUser(user);
                        });
                      },
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context, ref),
                    icon: Icon(
                      Icons.logout,
                      color: isDark ? AppColors.primaryLight : AppColors.primary,
                    ),
                    label: Text(
                      'Sair da conta',
                      style: TextStyle(
                        color:
                            isDark ? AppColors.primaryLight : AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark
                            ? AppColors.primaryLight
                            : AppColors.primary,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDeleteAccount(context, ref),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                    ),
                    label: const Text(
                      'Apagar conta',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Sair',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AuthBloc>().add(const AuthEvent.logoutRequested());
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded,
            color: AppColors.error, size: 40),
        title: const Text('Apagar conta'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'VocÃƒÂª estÃƒÂ¡ prestes a apagar permanentemente sua conta e todos os dados associados.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'Esta aÃƒÂ§ÃƒÂ£o nÃƒÂ£o pode ser desfeita.',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Apagar minha conta',
              style: TextStyle(
                  color: AppColors.error, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    // Backend integration pending: integrar com DELETE /users/me quando o endpoint existir.
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Funcionalidade em breve')),
      );
    }
  }
}



