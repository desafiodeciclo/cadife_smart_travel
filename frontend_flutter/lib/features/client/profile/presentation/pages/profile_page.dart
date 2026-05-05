import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cadife_smart_travel/features/client/profile/presentation/providers/profile_provider.dart';
import 'package:cadife_smart_travel/features/client/profile/presentation/widgets/profile_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Tela de perfil do cliente.
///
/// Exibe dados pessoais (nome editÃƒÂ¡vel, email, telefone read-only),
/// preferÃƒÂªncias de viagem via chips (tipo_viagem, preferencias),
/// toggle de passaporte vÃƒÂ¡lido, controle de tema e logout.
///
/// Integra com GET /users/me e PATCH /users/me via [IProfileRepository].
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
        ShadToaster.of(context).show(
          const ShadToast(
            description: Text('Perfil atualizado com sucesso'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            description: Text('Erro ao salvar. Tente novamente.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);
    final themeMode = ref.watch(themeModeProvider);

    return PageScaffold(
      title: 'MEU PERFIL',
      showProfile: false,
      body: userAsync.when(
        loading: () =>
            const AppLoadingWidget(message: 'Carregando perfil...'),
        error: (e, _) => AppErrorWidget(
          message: 'Erro ao carregar perfil. Tente novamente.',
          onRetry: () => ref.invalidate(userProfileProvider),
        ),
        data: (user) {
          if (!_isEditing) _syncFromUser(user);
          return _buildContent(context, user, themeMode);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AuthUser? user,
    ThemeMode themeMode,
  ) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 72)),
        // ── Header com avatar e nome ──────────────────────────────
        SliverToBoxAdapter(
          child: ProfileHeader(
            user: user,
            isEditing: _isEditing,
            nameController: _nameController,
            onToggleEdit: () => setState(() => _isEditing = !_isEditing),
          ),
        ),

        // ── Dados Pessoais ────────────────────────────────────────
        SliverToBoxAdapter(
          child: ProfileSectionCard(
            title: 'Dados Pessoais',
            children: [
              ProfileInfoRow(
                icon: Icons.email_outlined,
                label: 'E-mail',
                value: user?.email ?? '—',
              ),
              const SizedBox(height: 16),
              ProfileInfoRow(
                icon: Icons.phone_outlined,
                label: 'Telefone',
                value: user?.phone ?? 'Não informado',
                readOnly: true,
              ),
              const SizedBox(height: 16),
              ProfileInfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Membro desde',
                value: user?.createdAt != null
                    ? DateFormat('dd/MM/yyyy').format(user!.createdAt!)
                    : '—',
              ),
            ],
          ),
        ),

        // ── Preferências de Viagem ────────────────────────────────
        SliverToBoxAdapter(
          child: ProfileSectionCard(
            title: 'Preferências de Viagem',
            children: [
              ProfileChipGroup(
                label: 'Tipo de viagem',
                options: _tipoViagemOptions,
                selected: _tipoViagemSelected,
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
                label: 'Preferências',
                options: _preferenciasOptions,
                selected: _preferenciasSelected,
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

        // ── Passaporte ───────────────────────────────────────────
        SliverToBoxAdapter(
          child: ProfilePassaporteCard(
            value: _temPassaporte,
            onToggle: _isEditing
                ? () => setState(
                    () => _temPassaporte = !(_temPassaporte ?? false))
                : null,
          ),
        ),

        // ── Aparência (tema) ──────────────────────────────────────
        SliverToBoxAdapter(
          child: ProfileSectionCard(
            title: 'Aparência',
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
              ),
            ],
          ),
        ),

        // ── Ações (salvar / logout / apagar conta) ──────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                if (_isEditing) ...[
                  CadifeButton(
                    onPressed: _isSaving ? null : () => _save(user),
                    isLoading: _isSaving,
                    text: 'Salvar alterações',
                  ),
                  const SizedBox(height: 12),
                  CadifeButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        _hasSynced = false;
                        _syncFromUser(user);
                      });
                    },
                    text: 'Cancelar',
                    isOutline: true,
                  ),
                  const SizedBox(height: 12),
                ],
                CadifeButton(
                  onPressed: () => _confirmLogout(context, ref),
                  text: 'Sair da conta',
                  icon: Icons.logout,
                  isOutline: true,
                ),
                const SizedBox(height: 12),
                CadifeButton(
                  onPressed: () => _confirmDeleteAccount(context, ref),
                  text: 'Apagar conta',
                  icon: Icons.delete_outline,
                  isOutline: true,
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
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (ctx) => ShadDialog(
        title: const Text('Sair da conta'),
        description: const Text('Tem certeza que deseja sair?'),
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

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (ctx) => ShadDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 8),
            Text('Apagar conta'),
          ],
        ),
        description: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Você está prestes a apagar permanentemente sua conta e todos os dados associados.',
            ),
            SizedBox(height: 12),
            Text(
              'Esta ação não pode ser desfeita.',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.error),
            ),
          ],
        ),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ShadButton.destructive(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Apagar minha conta'),
          ),
        ],
      ),
    );

    // Backend integration pending: integrar com DELETE /users/me quando o endpoint existir.
    if (confirmed == true && context.mounted) {
      ShadToaster.of(context).show(
        const ShadToast(
          description: Text('Funcionalidade em breve'),
        ),
      );
    }
  }
}




