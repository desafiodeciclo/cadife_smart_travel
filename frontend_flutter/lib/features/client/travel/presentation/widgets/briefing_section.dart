import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Generic expandable section for the briefing tab.
///
/// Renders a themed [ExpansionTile] with a leading emoji icon and a count
/// badge when [itemCount] > 0.
class BriefingSection extends StatelessWidget {
  const BriefingSection({
    required this.title,
    required this.icon,
    required this.children,
    super.key,
    this.itemCount,
    this.initiallyExpanded = false,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final int? itemCount;
  final bool initiallyExpanded;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: cadife.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cadife.cardBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          // Remove default divider injected by ExpansionTile
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cadife.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: cadife.primary),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cadife.textPrimary,
                    ),
                  ),
                ),
                if (itemCount != null && itemCount! > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: cadife.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$itemCount',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: cadife.primary,
                      ),
                    ),
                  ),
                ],
                if (trailing != null) ...[
                  const SizedBox(width: 4),
                  trailing!,
                ],
              ],
            ),
            iconColor: cadife.textSecondary,
            collapsedIconColor: cadife.textSecondary,
            children: children,
          ),
        ),
      ),
    );
  }
}
