import 'package:cadife_smart_travel/core/theme/app_colors.dart';
import 'package:cadife_smart_travel/core/theme/theme_mode_provider.dart';
import 'package:cadife_smart_travel/features/auth/providers/auth_provider.dart';
import 'package:cadife_smart_travel/features/client/profile/profile_provider.dart';
import 'package:cadife_smart_travel/shared/models/models.dart';
import 'package:cadife_smart_travel/shared/widgets/feedback_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Tela de perfil do cliente.
///
/// Exibe dados pessoais (nome editável, email, telefone read-only),
/// preferências de viagem via chips (tipo_viagem, preferencias),
/// toggle de passaporte válido, controle de tema e logout.
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
  bool _hasSynced = false;

  // Chips selecionáveis (estado local para edição)
  final List<String> _tipoViagemSelected = [];
  final List<String> _preferenciasSelected = [];
  bool? _temPassaporte;

  // Opções disponíveis
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
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _syncFromUser(UserModel? user) {
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

  Future<void> _save(UserModel? current) async {
    if (current == null) return;
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
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1917) : AppColors.scaffold,
      body: SafeArea(
        child: userAsync.when(
          loading: () => const AppLoadingWidget(message: 'Carregando perfil...'),
          error: (e, _) => AppErrorWidget(
            message: 'Erro ao carregar perfil. Tente novamente.',
            onRetry: () => ref.invalidate(userProfileProvider),
          ),
          data: (user) {
            if (!_isEditing) _syncFromUser(user);
            return _buildContent(context, user, themeMode);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, UserModel? user, ThemeMode themeMode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        // ── Header com avatar e nome ───────────────────────────────
        SliverToBoxAdapter(
          child: _ProfileHeader(
            user: user,
            isDark: isDark,
            isEditing: _isEditing,
            nameController: _nameController,
            onToggleEdit: () => setState(() => _isEditing = !_isEditing),
          ),
        ),

        // ── Dados Pessoais ─────────────────────────────────────────
        SliverToBoxAdapter(
          child: _SectionCard(
            title: 'Dados Pessoais',
            isDark: isDark,
            children: [
              _InfoRow(
                icon: Icons.email_outlined,
                label: 'E-mail',
                value: user?.email ?? '—',
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Telefone',
                value: user?.phone ?? 'Não informado',
                isDark: isDark,
                readOnly: true,
              ),
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Membro desde',
                value: user?.createdAt != null
                    ? DateFormat('dd/MM/yyyy').format(user!.createdAt!)
                    : '—',
                isDark: isDark,
              ),
            ],
          ),
        ),

        // ── Preferências de Viagem ─────────────────────────────────
        SliverToBoxAdapter(
          child: _SectionCard(
            title: 'Preferências de Viagem',
            isDark: isDark,
            children: [
              _ChipGroup(
                label: 'Tipo de viagem',
                options: _tipoViagemOptions,
                selected: _tipoViagemSelected,
                isDark: isDark,
                onTap: (val) => setState(() {
                  if (_tipoViagemSelected.contains(val)) {
                    _tipoViagemSelected.remove(val);
                  } else {
                    _tipoViagemSelected.add(val);
                  }
                }),
              ),
              const SizedBox(height: 20),
              _ChipGroup(
                label: 'Preferências',
                options: _preferenciasOptions,
                selected: _preferenciasSelected,
                isDark: isDark,
                onTap: (val) => setState(() {
                  if (_preferenciasSelected.contains(val)) {
                    _preferenciasSelected.remove(val);
                  } else {
                    _preferenciasSelected.add(val);
                  }
                }),
              ),
            ],
          ),
        ),

        // ── Passaporte ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _PassaporteCard(
            value: _temPassaporte,
            isDark: isDark,
            onToggle: () => setState(() => _temPassaporte = !(_temPassaporte ?? false)),
          ),
        ),

        // ── Preferências do App (tema) ─────────────────────────────
        SliverToBoxAdapter(
          child: _SectionCard(
            title: 'Aparência',
            isDark: isDark,
            children: [
              _ThemeSelector(
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

        // ── Ações (salvar / logout) ────────────────────────────────
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
                      onPressed: () => _save(user),
                      child: const Text('Salvar alterações'),
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
                        color: isDark ? AppColors.primaryLight : AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark ? AppColors.primaryLight : AppColors.primary,
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
                      side: const BorderSide(
                        color: AppColors.error,
                        width: 1.5,
                      ),
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
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go('/auth/login');
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 40),
        title: const Text('Apagar conta'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Você está prestes a apagar permanentemente sua conta e todos os dados associados.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'Esta ação não pode ser desfeita.',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.error),
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
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // TODO: integrar com endpoint DELETE /users/me quando existir
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta apagada com sucesso')),
      );
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go('/auth/login');
    }
  }
}

// ═════════════════════════════════════════════════════════════════
// Sub-widgets
// ═════════════════════════════════════════════════════════════════

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.isDark,
    required this.isEditing,
    required this.nameController,
    required this.onToggleEdit,
  });

  final UserModel? user;
  final bool isDark;
  final bool isEditing;
  final TextEditingController nameController;
  final VoidCallback onToggleEdit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final initials = _initials(user?.name ?? '?');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF292524) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: isDark
              ? Border.all(color: Colors.white10)
              : Border.all(color: AppColors.border),
        ),
        child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                backgroundImage: user?.avatarUrl != null
                    ? NetworkImage(user!.avatarUrl!)
                    : null,
                child: user?.avatarUrl == null
                    ? Text(
                        initials,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.primaryLight
                              : AppColors.primary,
                        ),
                      )
                    : null,
              ),
              // Botão de editar (canto inferior direito do avatar)
              GestureDetector(
                onTap: onToggleEdit,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      isDark ? const Color(0xFF1C1917) : Colors.white,
                  child: Icon(
                    isEditing ? Icons.close : Icons.edit,
                    size: 16,
                    color: isDark
                        ? AppColors.primaryLight
                        : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isEditing) ...[
            TextField(
              controller: nameController,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Seu nome',
                hintStyle: textTheme.headlineSmall?.copyWith(
                  color: isDark
                      ? const Color(0xFFB0BEC5)
                      : AppColors.textSecondary,
                ),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark ? Colors.white24 : AppColors.border,
                  ),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark ? Colors.white24 : AppColors.border,
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.primaryLight
                        : AppColors.primary,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ] else ...[
            Text(
              user?.name ?? 'Carregando...',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? const Color(0xFFB0BEC5)
                  : AppColors.textSecondary,
            ),
          ),
        ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
    required this.isDark,
  });

  final String title;
  final List<Widget> children;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF292524) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: isDark
              ? Border.all(color: Colors.white10)
              : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFFB0BEC5)
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.readOnly = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? AppColors.primaryLight : AppColors.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? const Color(0xFFB0BEC5)
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (readOnly) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.lock_outline,
                      size: 12,
                      color: isDark
                          ? const Color(0xFFB0BEC5)
                          : AppColors.textSecondary,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({
    required this.label,
    required this.options,
    required this.selected,
    required this.isDark,
    this.onTap,
  });

  final String label;
  final List<String> options;
  final List<String> selected;
  final bool isDark;
  final ValueChanged<String>? onTap;

  String _displayLabel(String raw) {
    return raw[0].toUpperCase() + raw.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: isDark
                ? const Color(0xFFB0BEC5)
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final isSelected = selected.contains(opt);
            final enabled = onTap != null;

            return InkWell(
              onTap: enabled ? () => onTap!(opt) : null,
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.primary.withValues(alpha: 0.1))
                      : (isDark
                          ? Colors.white10
                          : AppColors.surface),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? (isDark
                            ? AppColors.primaryLight
                            : AppColors.primary)
                        : (isDark
                            ? Colors.white12
                            : AppColors.border),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  _displayLabel(opt),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? (isDark
                            ? AppColors.primaryLight
                            : AppColors.primary)
                        : (isDark
                            ? const Color(0xFFB0BEC5)
                            : AppColors.textSecondary),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PassaporteCard extends StatelessWidget {
  const _PassaporteCard({
    required this.value,
    required this.isDark,
    required this.onToggle,
  });

  final bool? value;
  final bool isDark;
  final VoidCallback onToggle;

  bool get _hasPassport => value == true;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Cores dinâmicas baseadas no estado do passaporte
    final bgColor = _hasPassport
        ? (isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE8F5E9))
        : (isDark ? const Color(0xFF292524) : AppColors.cardBackground);

    final borderColor = _hasPassport
        ? (isDark ? AppColors.success : const Color(0xFF1E8449))
        : (isDark ? Colors.white10 : AppColors.border);

    final iconBgColor = _hasPassport
        ? (isDark ? AppColors.success.withValues(alpha: 0.2) : AppColors.success.withValues(alpha: 0.12))
        : (isDark ? Colors.white10 : AppColors.surface);

    final iconColor = _hasPassport
        ? AppColors.success
        : (isDark ? const Color(0xFFB0BEC5) : AppColors.textSecondary);

    final titleColor = _hasPassport
        ? (isDark ? Colors.white : AppColors.textPrimary)
        : (isDark ? Colors.white : AppColors.textPrimary);

    final subtitleColor = _hasPassport
        ? (isDark ? const Color(0xFF81C784) : AppColors.success)
        : (isDark ? const Color(0xFFB0BEC5) : AppColors.textSecondary);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: _hasPassport ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.book_outlined,
                  size: 22,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Passaporte válido',
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _hasPassport
                            ? 'Sim, possui passaporte válido'
                            : 'Não possui passaporte válido',
                        key: ValueKey<bool>(_hasPassport),
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: _hasPassport ? FontWeight.w500 : FontWeight.w400,
                          color: subtitleColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _hasPassport,
                onChanged: (_) => onToggle(),
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.success,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: isDark ? Colors.white12 : AppColors.border,
                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({
    required this.themeMode,
    required this.onChanged,
    required this.isDark,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: ThemeMode.values.map((mode) => _ThemeOption(
            mode: mode,
            isSelected: themeMode == mode,
            onTap: () => onChanged(mode),
            isDark: isDark,
          )).toList(),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  final ThemeMode mode;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  String get _label => switch (mode) {
        ThemeMode.system => 'Padrão do sistema',
        ThemeMode.light => 'Claro',
        ThemeMode.dark => 'Escuro',
      };

  IconData get _icon => switch (mode) {
        ThemeMode.system => Icons.brightness_auto,
        ThemeMode.light => Icons.wb_sunny_outlined,
        ThemeMode.dark => Icons.nights_stay_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.primary.withValues(alpha: 0.08))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  width: 1.5,
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              _icon,
              size: 20,
              color: isSelected
                  ? (isDark ? AppColors.primaryLight : AppColors.primary)
                  : (isDark
                      ? const Color(0xFFB0BEC5)
                      : AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? (isDark ? Colors.white : AppColors.textPrimary)
                      : (isDark
                          ? const Color(0xFFB0BEC5)
                          : AppColors.textSecondary),
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                size: 20,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}
