import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/settings/application/theme_notifier.dart';
import 'package:cadife_smart_travel/features/settings/domain/entities/user_preferences.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.user,
    required this.isEditing,
    required this.nameController,
    required this.onToggleEdit,
  });

  final AuthUser? user;
  final bool isEditing;
  final TextEditingController nameController;
  final VoidCallback onToggleEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cadife = context.cadife;
    final isDark = context.isDark;
    final initials = _initials(user?.name ?? '?');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ShadCard(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        backgroundColor: isDark ? context.cadife.cardBackground : Colors.white,
        radius: BorderRadius.circular(24),
        border: ShadBorder.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : context.cadife.cardBorder,
          width: 1,
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: ShadAvatar(
                    user?.avatarUrl != null ? user!.avatarUrl! : '',
                    size: const Size.square(108),
                    placeholder: Text(
                      initials,
                      style: GoogleFonts.inter(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.primary,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onToggleEdit,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? context.cadife.background : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.white10 : context.cadife.cardBorder,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      isEditing ? Icons.check : Icons.edit_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isEditing) ...[
              ShadInput(
                controller: nameController,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cadife.textPrimary,
                ),
                placeholder: Text(
                  'Seu nome',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: cadife.textSecondary.withValues(alpha: 0.4),
                  ),
                ),
                padding: EdgeInsets.zero,
                decoration: ShadDecoration(
                  border: ShadBorder(
                    bottom: ShadBorderSide(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  focusedBorder: const ShadBorder(
                    bottom: ShadBorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ] else ...[
              Text(
                user?.name ?? 'Carregando...',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cadife.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              user?.email ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cadife.textSecondary,
                fontWeight: FontWeight.w500,
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

class ProfileSectionCard extends StatelessWidget {
  const ProfileSectionCard({
    super.key,
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

class ProfileInfoRow extends StatelessWidget {
  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.readOnly = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cadife = context.cadife;
    final isDark = context.isDark;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? Colors.white70 : AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cadife.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (readOnly) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 12,
                      color: cadife.textSecondary.withValues(alpha: 0.5),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cadife.textPrimary,
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

class ProfileChipGroup extends StatelessWidget {
  const ProfileChipGroup({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    this.onTap,
  });

  final String label;
  final List<String> options;
  final List<String> selected;
  final ValueChanged<String>? onTap;

  String _displayLabel(String raw) =>
      raw[0].toUpperCase() + raw.substring(1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cadife = context.cadife;
    final isDark = context.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: cadife.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: options.map((opt) {
            final isSelected = selected.contains(opt);
            final enabled = onTap != null;

            return InkWell(
              onTap: enabled ? () => onTap!(opt) : null,
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? Colors.white.withValues(alpha: 0.05) : context.cadife.surface),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? Colors.white.withValues(alpha: 0.05) : context.cadife.cardBorder),
                    width: 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ] : null,
                ),
                child: Text(
                  _displayLabel(opt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? cadife.textSecondary
                            : context.cadife.textPrimary),
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

class ProfilePassaporteCard extends StatelessWidget {
  const ProfilePassaporteCard({
    super.key,
    required this.value,
    this.onToggle,
  });

  final bool? value;
  final VoidCallback? onToggle;

  bool get _hasPassport => value == true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cadife = context.cadife;
    final isDark = context.isDark;

    final bgColor = _hasPassport
        ? (isDark ? AppColors.passaporteBgDark.withValues(alpha: 0.5) : AppColors.passaporteBgLight)
        : (isDark ? context.cadife.cardBackground : Colors.white);

    final borderColor = _hasPassport
        ? AppColors.success.withValues(alpha: 0.5)
        : (isDark ? Colors.white.withValues(alpha: 0.05) : context.cadife.cardBorder);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: borderColor,
            width: _hasPassport ? 2 : 1,
          ),
          boxShadow: [
            if (_hasPassport)
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.1),
                blurRadius: 20,
              ),
          ],
        ),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _hasPassport
                        ? AppColors.success.withValues(alpha: 0.1)
                        : (isDark ? Colors.white.withValues(alpha: 0.05) : context.cadife.surface),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.badge_outlined,
                    size: 24,
                    color: _hasPassport ? AppColors.success : cadife.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Passaporte válido',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cadife.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _hasPassport
                            ? 'Sim, possui passaporte válido'
                            : 'Não informado ou não possui',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _hasPassport ? AppColors.success : cadife.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ShadSwitch(
                  value: _hasPassport,
                  onChanged: onToggle != null ? (_) => onToggle!() : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileThemeSelector extends StatelessWidget {
  const ProfileThemeSelector({
    super.key,
    required this.themePreference,
    required this.onChanged,
  });

  final ThemePreference themePreference;
  final ValueChanged<ThemePreference> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: ThemePreference.values
          .map((pref) => _ProfileThemeOption(
                pref: pref,
                isSelected: themePreference == pref,
                onTap: () => onChanged(pref),
              ))
          .toList(),
    );
  }
}

class _ProfileThemeOption extends StatelessWidget {
  const _ProfileThemeOption({
    required this.pref,
    required this.isSelected,
    required this.onTap,
  });

  final ThemePreference pref;
  final bool isSelected;
  final VoidCallback onTap;

  String get _label => switch (pref) {
        ThemePreference.system => 'Padrão do sistema',
        ThemePreference.light => 'Modo Claro',
        ThemePreference.dark => 'Modo Escuro',
      };

  IconData get _icon => switch (pref) {
        ThemePreference.system => Icons.settings_brightness_rounded,
        ThemePreference.light => Icons.light_mode_rounded,
        ThemePreference.dark => Icons.dark_mode_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cadife = context.cadife;
    final isDark = context.isDark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _icon,
                size: 22,
                color: isSelected ? AppColors.primary : cadife.textSecondary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? cadife.textPrimary : cadife.textSecondary,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
