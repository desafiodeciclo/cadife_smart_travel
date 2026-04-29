import 'package:cadife_smart_travel/core/theme/app_colors.dart';
import 'package:cadife_smart_travel/shared/models/models.dart';
import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
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
          color: isDark ? AppColors.darkCard : AppColors.cardBackground,
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
                GestureDetector(
                  onTap: onToggleEdit,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        isDark ? AppColors.darkSurface : Colors.white,
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
                        ? AppColors.darkTextHint
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
                      color: isDark ? AppColors.primaryLight : AppColors.primary,
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
                color: isDark ? AppColors.darkTextHint : AppColors.textSecondary,
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
          color: isDark ? AppColors.darkCard : AppColors.cardBackground,
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
                color: isDark ? AppColors.darkTextHint : AppColors.textSecondary,
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

class ProfileInfoRow extends StatelessWidget {
  const ProfileInfoRow({
    super.key,
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
                          ? AppColors.darkTextHint
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (readOnly) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.lock_outline,
                      size: 12,
                      color: isDark
                          ? AppColors.darkTextHint
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

class ProfileChipGroup extends StatelessWidget {
  const ProfileChipGroup({
    super.key,
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

  String _displayLabel(String raw) =>
      raw[0].toUpperCase() + raw.substring(1);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: isDark ? AppColors.darkTextHint : AppColors.textSecondary,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.primary.withValues(alpha: 0.1))
                      : (isDark ? Colors.white10 : AppColors.surface),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? (isDark ? AppColors.primaryLight : AppColors.primary)
                        : (isDark ? Colors.white12 : AppColors.border),
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
                        ? (isDark ? AppColors.primaryLight : AppColors.primary)
                        : (isDark
                            ? AppColors.darkTextHint
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

class ProfilePassaporteCard extends StatelessWidget {
  const ProfilePassaporteCard({
    super.key,
    required this.value,
    required this.isDark,
    this.onToggle,
  });

  final bool? value;
  final bool isDark;
  final VoidCallback? onToggle;

  bool get _hasPassport => value == true;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final bgColor = _hasPassport
        ? (isDark ? AppColors.passaporteBgDark : AppColors.passaporteBgLight)
        : (isDark ? AppColors.darkCard : AppColors.cardBackground);

    final borderColor = _hasPassport
        ? AppColors.success
        : (isDark ? Colors.white10 : AppColors.border);

    final iconBgColor = _hasPassport
        ? (isDark
            ? AppColors.success.withValues(alpha: 0.2)
            : AppColors.success.withValues(alpha: 0.12))
        : (isDark ? Colors.white10 : AppColors.surface);

    final iconColor = _hasPassport
        ? AppColors.success
        : (isDark ? AppColors.darkTextHint : AppColors.textSecondary);

    final subtitleColor = _hasPassport
        ? (isDark ? AppColors.successTextDark : AppColors.success)
        : (isDark ? AppColors.darkTextHint : AppColors.textSecondary);

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
                child: Icon(Icons.book_outlined, size: 22, color: iconColor),
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
                        color: isDark ? Colors.white : AppColors.textPrimary,
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
                          fontWeight: _hasPassport
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: subtitleColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _hasPassport,
                onChanged: onToggle != null ? (_) => onToggle!() : null,
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

class ProfileThemeSelector extends StatelessWidget {
  const ProfileThemeSelector({
    super.key,
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
      children: ThemeMode.values
          .map((mode) => _ProfileThemeOption(
                mode: mode,
                isSelected: themeMode == mode,
                onTap: () => onChanged(mode),
                isDark: isDark,
              ))
          .toList(),
    );
  }
}

class _ProfileThemeOption extends StatelessWidget {
  const _ProfileThemeOption({
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
                  : (isDark ? AppColors.darkTextHint : AppColors.textSecondary),
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
                          ? AppColors.darkTextHint
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
