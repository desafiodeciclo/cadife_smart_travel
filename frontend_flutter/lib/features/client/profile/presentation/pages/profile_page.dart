import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cadife_smart_travel/features/client/profile/presentation/providers/profile_provider.dart';
import 'package:cadife_smart_travel/features/client/profile/presentation/widgets/diary_widgets.dart';
import 'package:cadife_smart_travel/features/client/profile/presentation/widgets/profile_widgets.dart';
import 'package:cadife_smart_travel/features/client/profile/presentation/widgets/suitcase_widgets.dart';
import 'package:cadife_smart_travel/features/settings/application/theme_notifier.dart';
import 'package:cadife_smart_travel/features/settings/domain/entities/user_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({this.initialTabIndex = 0, super.key});

  final int initialTabIndex;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;
  bool _hasSynced = false;

  final List<String> _tipoViagemSelected = [];
  bool? _temPassaporte;

  static const _tipoViagemOptions = [
    'turismo',
    'lazer',
    'aventura',
    'imigração',
    'negócios',
  ];


  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _syncFromUser(AuthUser? user) {
    if (user == null || _hasSynced) return;
    _nameController.text = user.name;
    _bioController.text = user.bio ?? '';
    _phoneController.text = user.phone ?? '';
    _tipoViagemSelected
      ..clear()
      ..addAll(user.tipoViagem ?? []);
    _temPassaporte = user.temPassaporte;
    _hasSynced = true;
  }

  Future<void> _save(AuthUser? current) async {
    if (current == null) return;
    final success = await ref.read(userProfileProvider.notifier).updateProfile(
          name: _nameController.text.trim(),
          bio: _bioController.text.trim(),
          phone: _phoneController.text.trim(),
          tipoViagem: List<String>.from(_tipoViagemSelected),
          temPassaporte: _temPassaporte,
        );
    if (mounted) {
      if (success) {
        setState(() {
          _isEditing = false;
          _hasSynced = false;
        });
        ShadToaster.of(context).show(
          const ShadToast(description: Text('Perfil atualizado com sucesso')),
        );
      } else {
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            description: Text('Erro ao salvar. Tente novamente.'),
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: context.cadife.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Alterar foto de perfil',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.cadife.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickOption(
                  icon: LucideIcons.camera,
                  label: 'Câmera',
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                _buildPickOption(
                  icon: LucideIcons.image,
                  label: 'Galeria',
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (source != null) {
      final image = await picker.pickImage(source: source);
      if (image != null && mounted) {
        // Aqui integraria com upload de imagem. Por ora apenas mostra feedback.
        ShadToaster.of(context).show(
          const ShadToast(description: Text('Upload de foto em breve')),
        );
      }
    }
  }

  Widget _buildPickOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final cadife = context.cadife;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cadife.textPrimary,
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);
    final cadife = context.cadife;

    return Scaffold(
      backgroundColor: cadife.background,
      appBar: CadifeAppBar(
        title: 'Meu Perfil',
        showProfile: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings, size: 22),
            onPressed: () => context.push('/client/settings'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: userAsync.when(
        loading: () => const SafeArea(
          child: AppLoadingWidget(message: 'Carregando perfil...'),
        ),
        error: (e, _) => SafeArea(
          child: AppErrorWidget(
            message: 'Erro ao carregar perfil. Tente novamente.',
            onRetry: () => ref.invalidate(userProfileProvider),
          ),
        ),
        data: (user) {
          if (!_isEditing) _syncFromUser(user);
          return _buildTabLayout(context, user);
        },
      ),
    );
  }

  Widget _buildTabLayout(BuildContext context, AuthUser? user) {
    final cadife = context.cadife;
    final themePref = ref.watch(themeNotifierProvider);
    final isSaving = ref.watch(profileSaveStateProvider).isLoading;

    return SafeArea(
      child: Column(
        children: [
          // ── Header: avatar + greeting ──────────────────────────────────
          _ProfileStatsHeader(
            user: user,
            isEditing: _isEditing,
            nameController: _nameController,
            onToggleEdit: () => setState(() => _isEditing = !_isEditing),
            onPickImage: _pickImage,
          ),

          // ── Pinned TabBar ───────────────────────────────────────────────
          Material(
            color: cadife.background,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: cadife.textSecondary,
              labelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: 'Perfil'),
                Tab(text: 'Diários'),
                Tab(text: 'Minha Mala'),
              ],
            ),
          ),

          // ── Tab content (scrolls independently) ────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ProfileInfoTab(
                  user: user,
                  isEditing: _isEditing,
                  isSaving: isSaving,
                  nameController: _nameController,
                  bioController: _bioController,
                  phoneController: _phoneController,
                  tipoViagemSelected: _tipoViagemSelected,
                  tipoViagemOptions: _tipoViagemOptions,
                  temPassaporte: _temPassaporte,
                  themePreference: themePref.maybeWhen(
                    data: (p) => p,
                    orElse: () => ThemePreference.system,
                  ),
                  onToggleTipoViagem: (val) => setState(() {
                    if (_tipoViagemSelected.contains(val)) {
                      _tipoViagemSelected.remove(val);
                    } else {
                      _tipoViagemSelected.add(val);
                    }
                  }),
                  onTogglePassaporte: () => setState(
                      () => _temPassaporte = !(_temPassaporte ?? false)),
                  onSave: () => _save(user),
                  onCancel: () => setState(() {
                    _isEditing = false;
                    _hasSynced = false;
                    _syncFromUser(user);
                  }),
                  onLogout: () => _confirmLogout(context, ref),
                  onDeleteAccount: () => _confirmDeleteAccount(context, ref),
                  onThemeChanged: (pref) =>
                      ref.read(themeNotifierProvider.notifier).setTheme(pref),
                  onEditBio: () => _showEditBioDialog(context),
                  onEditPersonalData: () => _showEditPersonalDataDialog(context),
                  onEditTravelPreferences: () => setState(() => _isEditing = true),
                ),
                const DiariesTab(),
                const SuitcaseTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditBioDialog(BuildContext context) async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (ctx) => ShadDialog(
        title: const Text('Editar Bio'),
        description: const Text('Conte um pouco sobre suas experiÃªncias de viagem.'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ShadButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
        child: ShadInput(
          controller: _bioController,
          maxLines: 4,
          placeholder: const Text('Escreva sua bio...'),
        ),
      ),
    );

    if (confirmed == true) {
      setState(() => _isEditing = true);
    }
  }

  Future<void> _showEditPersonalDataDialog(BuildContext context) async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (ctx) => ShadDialog(
        title: const Text('Dados Pessoais'),
        description: const Text('Atualize suas informaÃ§Ãµes de contato.'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ShadButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShadInputFormField(
              id: 'name',
              controller: _nameController,
              label: const Text('Nome'),
              placeholder: const Text('Seu nome completo'),
            ),
            const SizedBox(height: 16),
            ShadInputFormField(
              id: 'phone',
              controller: _phoneController,
              label: const Text('Telefone'),
              placeholder: const Text('(00) 00000-0000'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      setState(() => _isEditing = true);
    }
  }
}

// ---------------------------------------------------------------------------
// Stats header
// ---------------------------------------------------------------------------

class _ProfileStatsHeader extends StatelessWidget {
  const _ProfileStatsHeader({
    required this.user,
    required this.isEditing,
    required this.nameController,
    required this.onToggleEdit,
    required this.onPickImage,
  });

  final AuthUser? user;
  final bool isEditing;
  final TextEditingController nameController;
  final VoidCallback onToggleEdit;
  final VoidCallback onPickImage;

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  static String _initials(String name) {
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final theme = Theme.of(context);
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      color: cadife.background,
      child: Row(
        children: [
          // Avatar with edit button
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: InkWell(
                  onTap: onPickImage,
                  borderRadius: BorderRadius.circular(60),
                  child: ShadAvatar(
                    user?.avatarUrl != null ? user!.avatarUrl! : '',
                    size: const Size.square(80),
                    placeholder: Text(
                      _initials(user?.name ?? '?'),
                      style: GoogleFonts.inter(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.primary,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: onPickImage,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        border: Border.all(color: cadife.background, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.pencil,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),
          // Greeting + name + country flags
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()},',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cadife.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.name ?? '...',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: cadife.textPrimary,
                    letterSpacing: -0.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile info tab (existing functionality)
// ---------------------------------------------------------------------------

class _ProfileInfoTab extends StatelessWidget {
  const _ProfileInfoTab({
    required this.user,
    required this.isEditing,
    required this.isSaving,
    required this.nameController,
    required this.bioController,
    required this.phoneController,
    required this.tipoViagemSelected,
    required this.tipoViagemOptions,
    required this.temPassaporte,
    required this.themePreference,
    required this.onToggleTipoViagem,
    required this.onTogglePassaporte,
    required this.onSave,
    required this.onCancel,
    required this.onLogout,
    required this.onDeleteAccount,
    required this.onThemeChanged,
    required this.onEditBio,
    required this.onEditPersonalData,
    required this.onEditTravelPreferences,
  });

  final AuthUser? user;
  final bool isEditing;
  final bool isSaving;
  final TextEditingController nameController;
  final TextEditingController bioController;
  final TextEditingController phoneController;
  final List<String> tipoViagemSelected;
  final List<String> tipoViagemOptions;
  final bool? temPassaporte;
  final ThemePreference themePreference;
  final ValueChanged<String> onToggleTipoViagem;
  final VoidCallback onTogglePassaporte;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;
  final ValueChanged<ThemePreference> onThemeChanged;
  final VoidCallback onEditBio;
  final VoidCallback onEditPersonalData;
  final VoidCallback onEditTravelPreferences;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ProfileSectionCard(
            title: 'Minha Bio',
            onEdit: onEditBio,
            children: [
              Text(
                bioController.text.isNotEmpty
                    ? bioController.text
                    : 'Escreva algo sobre você...',
                style: context.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: bioController.text.isNotEmpty
                      ? context.cadife.textPrimary
                      : context.cadife.textSecondary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: ProfileSectionCard(
            title: 'Dados Pessoais',
            onEdit: onEditPersonalData,
            children: [
              ProfileInfoRow(
                icon: Icons.person_outline,
                label: 'Nome',
                value: nameController.text.isNotEmpty ? nameController.text : 'Não informado',
              ),
              const SizedBox(height: 16),
              ProfileInfoRow(
                icon: Icons.email_outlined,
                label: 'E-mail',
                value: user?.email ?? '—',
                readOnly: true,
              ),
              const SizedBox(height: 16),
              ProfileInfoRow(
                icon: Icons.phone_outlined,
                label: 'Telefone',
                value: phoneController.text.isNotEmpty ? phoneController.text : 'Não informado',
              ),
              const SizedBox(height: 16),
              ProfileInfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Membro desde',
                value: user?.createdAt != null
                    ? DateFormat('dd/MM/yyyy').format(user!.createdAt!)
                    : '—',
                readOnly: true,
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: ProfileSectionCard(
            title: 'Preferências de Viagem',
            onEdit: onEditTravelPreferences,
            children: [
              ProfileChipGroup(
                label: 'Tipo de viagem',
                options: tipoViagemOptions,
                selected: tipoViagemSelected,
                onTap: isEditing ? onToggleTipoViagem : null,
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: ProfilePassaporteCard(
            value: temPassaporte,
            onToggle: isEditing ? onTogglePassaporte : null,
          ),
        ),
        SliverToBoxAdapter(
          child: ProfileSectionCard(
            title: 'Aparência',
            children: [
              ProfileThemeSelector(
                themePreference: themePreference,
                onChanged: onThemeChanged,
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: ProfileActionsSection(
            isEditing: isEditing,
            isSaving: isSaving,
            onSave: onSave,
            onCancel: onCancel,
            onLogout: onLogout,
            onDeleteAccount: onDeleteAccount,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Dialogs (module-level, unchanged from original)
// ---------------------------------------------------------------------------

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
    if (context.mounted) {
      context.go('/auth/login');
    }
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
      const ShadToast(description: Text('Funcionalidade em breve')),
    );
  }
}

// Removido extension que estava fora da classe _ProfileScreenState

