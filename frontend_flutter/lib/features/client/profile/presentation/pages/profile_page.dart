import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/client/profile/data/mocks/client_profile_mocks.dart';
import 'package:cadife_smart_travel/features/client/profile/presentation/providers/profile_provider.dart';
import 'package:cadife_smart_travel/features/client/profile/presentation/widgets/diary_widgets.dart';
import 'package:cadife_smart_travel/features/client/profile/presentation/widgets/profile_widgets.dart';
import 'package:cadife_smart_travel/features/client/profile/presentation/widgets/suitcase_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _nameController = TextEditingController();
  bool _isEditing = false;
  bool _hasSynced = false;

  final List<String> _tipoViagemSelected = [];
  final List<String> _preferenciasSelected = [];
  bool? _temPassaporte;

  static const _tipoViagemOptions = [
    'turismo',
    'lazer',
    'aventura',
    'imigração',
    'negócios',
  ];

  static const _preferenciasOptions = [
    'frio',
    'calor',
    'praia',
    'cidade',
    'luxo',
    'econômico',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    if (current == null) return;
    final success = await ref.read(userProfileProvider.notifier).updateProfile(
          name: _nameController.text.trim(),
          tipoViagem: List<String>.from(_tipoViagemSelected),
          preferencias: List<String>.from(_preferenciasSelected),
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

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);
    final cadife = context.cadife;

    return Scaffold(
      backgroundColor: cadife.background,
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
    final isSaving = ref.watch(profileSaveStateProvider).isLoading;

    return SafeArea(
      child: Column(
        children: [
          // ── Header: avatar + greeting + stats ──────────────────────────
          _ProfileStatsHeader(
            user: user,
            isEditing: _isEditing,
            nameController: _nameController,
            onToggleEdit: () => setState(() => _isEditing = !_isEditing),
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
                  tipoViagemSelected: _tipoViagemSelected,
                  preferenciasSelected: _preferenciasSelected,
                  tipoViagemOptions: _tipoViagemOptions,
                  preferenciasOptions: _preferenciasOptions,
                  temPassaporte: _temPassaporte,
                  onToggleTipoViagem: (val) => setState(() {
                    if (_tipoViagemSelected.contains(val)) {
                      _tipoViagemSelected.remove(val);
                    } else {
                      _tipoViagemSelected.add(val);
                    }
                  }),
                  onTogglePreferencia: (val) => setState(() {
                    if (_preferenciasSelected.contains(val)) {
                      _preferenciasSelected.remove(val);
                    } else {
                      _preferenciasSelected.add(val);
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
  });

  final AuthUser? user;
  final bool isEditing;
  final TextEditingController nameController;
  final VoidCallback onToggleEdit;

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
                child: ShadAvatar(
                  user?.avatarUrl != null ? user!.avatarUrl! : '',
                  size: const Size.square(64),
                  placeholder: Text(
                    _initials(user?.name ?? '?'),
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.primary,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onToggleEdit,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                      border: Border.all(color: cadife.background, width: 2),
                    ),
                    child: Icon(
                      isEditing ? LucideIcons.check : LucideIcons.pencil,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

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
                const SizedBox(height: 6),
                // Country flags
                const _CountryFlags(isoCodes: ClientProfileMocks.mockCountriesIso),
              ],
            ),
          ),

          // Stats column + Settings Icon
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => context.push('/client/settings'),
                child: Icon(
                  LucideIcons.settings,
                  size: 20,
                  color: cadife.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              const _MiniStat(
                icon: LucideIcons.plane,
                value: '${ClientProfileMocks.mockTotalTrips}',
                label: 'viagens',
              ),
              const SizedBox(height: 8),
              _MiniStat(
                icon: LucideIcons.globe,
                value: '${ClientProfileMocks.mockCountriesIso.length}',
                label: 'países',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cadife.textPrimary,
                ),
              ),
              TextSpan(
                text: ' $label',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cadife.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CountryFlags extends StatelessWidget {
  const _CountryFlags({required this.isoCodes});

  final List<String> isoCodes;

  static String _flag(String iso) {
    final units = iso.toUpperCase().codeUnits;
    return String.fromCharCode(units[0] + 127397) +
        String.fromCharCode(units[1] + 127397);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: isoCodes
          .map(
            (code) => Tooltip(
              message: code,
              child: Text(_flag(code),
                  style: const TextStyle(fontSize: 18)),
            ),
          )
          .toList(),
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
    required this.tipoViagemSelected,
    required this.preferenciasSelected,
    required this.tipoViagemOptions,
    required this.preferenciasOptions,
    required this.temPassaporte,
    required this.onToggleTipoViagem,
    required this.onTogglePreferencia,
    required this.onTogglePassaporte,
    required this.onSave,
    required this.onCancel,
  });

  final AuthUser? user;
  final bool isEditing;
  final bool isSaving;
  final TextEditingController nameController;
  final List<String> tipoViagemSelected;
  final List<String> preferenciasSelected;
  final List<String> tipoViagemOptions;
  final List<String> preferenciasOptions;
  final bool? temPassaporte;
  final ValueChanged<String> onToggleTipoViagem;
  final ValueChanged<String> onTogglePreferencia;
  final VoidCallback onTogglePassaporte;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
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
        SliverToBoxAdapter(
          child: ProfileSectionCard(
            title: 'Preferências de Viagem',
            children: [
              ProfileChipGroup(
                label: 'Tipo de viagem',
                options: tipoViagemOptions,
                selected: tipoViagemSelected,
                onTap: isEditing ? onToggleTipoViagem : null,
              ),
              const SizedBox(height: 20),
              ProfileChipGroup(
                label: 'Preferências',
                options: preferenciasOptions,
                selected: preferenciasSelected,
                onTap: isEditing ? onTogglePreferencia : null,
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
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  Text(
                    'Cadife Smart Travel',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: context.cadife.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Versão 1.0.0 (build 42)',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.cadife.textSecondary.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: ProfileActionsSection(
            isEditing: isEditing,
            isSaving: isSaving,
            onSave: onSave,
            onCancel: onCancel,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

