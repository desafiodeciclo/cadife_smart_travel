import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/travel/domain/entities/briefing_flag.dart';
import 'package:flutter/material.dart';

/// Displays a single briefing key-value row with optional flag buttons.
///
/// [fieldKey] is the internal identifier used when persisting flags.
/// [label]   is the human-readable field name.
/// [value]   is the current field value (null renders a placeholder).
/// [currentFlag] reflects any flag the client has set on this field.
/// [onFlag]  is called when the client taps a flag button.
class BriefingDataCard extends StatelessWidget {
  const BriefingDataCard({
    required this.fieldKey,
    required this.label,
    super.key,
    this.value,
    this.currentFlag,
    this.onFlag,
    this.valueWidget,
  });

  final String fieldKey;
  final String label;
  final String? value;
  final Widget? valueWidget;
  final BriefingFlagType? currentFlag;
  final void Function(BriefingFlagType type)? onFlag;

  bool get _hasValue => (value != null && value!.isNotEmpty) || valueWidget != null;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;

    Color? flagBg;
    if (currentFlag == BriefingFlagType.incerto) {
      flagBg = const Color(0xFFFFF3CD); // amber tint
    } else if (currentFlag == BriefingFlagType.incorreto) {
      flagBg = const Color(0xFFFFEBEB); // red tint
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: flagBg ?? cadife.muted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: currentFlag == BriefingFlagType.incorreto
              ? AppColors.primary.withValues(alpha: 0.4)
              : currentFlag == BriefingFlagType.incerto
                  ? AppColors.warning.withValues(alpha: 0.4)
                  : Colors.transparent,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Flag indicator
          if (currentFlag != null)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 2),
              child: Text(
                currentFlag!.emoji,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          // Label + value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: cadife.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                valueWidget ??
                    Text(
                      _hasValue ? value! : '—',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _hasValue
                            ? cadife.textPrimary
                            : cadife.textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
              ],
            ),
          ),
          // Flag buttons (only when onFlag handler provided)
          if (onFlag != null) _FlagButtons(currentFlag: currentFlag, onFlag: onFlag!),
        ],
      ),
    );
  }
}

class _FlagButtons extends StatelessWidget {
  const _FlagButtons({required this.onFlag, this.currentFlag});

  final BriefingFlagType? currentFlag;
  final void Function(BriefingFlagType) onFlag;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FlagChip(
          label: '⚠️',
          tooltip: 'Marcar como incerto',
          active: currentFlag == BriefingFlagType.incerto,
          activeColor: AppColors.warning,
          onTap: () => onFlag(BriefingFlagType.incerto),
        ),
        const SizedBox(height: 4),
        _FlagChip(
          label: '🚫',
          tooltip: 'Marcar como incorreto',
          active: currentFlag == BriefingFlagType.incorreto,
          activeColor: AppColors.primary,
          onTap: () => onFlag(BriefingFlagType.incorreto),
        ),
      ],
    );
  }
}

class _FlagChip extends StatelessWidget {
  const _FlagChip({
    required this.label,
    required this.tooltip,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final String tooltip;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 30,
          height: 26,
          decoration: BoxDecoration(
            color: active
                ? activeColor.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: active ? activeColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
      ),
    );
  }
}
