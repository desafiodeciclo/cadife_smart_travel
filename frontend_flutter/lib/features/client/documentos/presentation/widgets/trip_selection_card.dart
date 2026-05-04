import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/documentos/domain/entities/trip_summary.dart';
import 'package:flutter/material.dart';

class TripSelectionCard extends StatelessWidget {
  const TripSelectionCard({
    super.key,
    required this.trip,
    this.onTap,
  });

  final TripSummary trip;
  final VoidCallback? onTap;

  String _formatDate(DateTime? date) {
    if (date == null) return '--/--/--';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.5);

    return ShadCard(
      padding: EdgeInsets.zero,
      backgroundColor: theme.cardTheme.color ?? (isDark ? context.cadife.cardBackground : Colors.white),
      radius: BorderRadius.circular(16),
      border: ShadBorder.all(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
        width: 1,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Trip Illustration Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 84,
                    height: 84,
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                    child: trip.imageUrl != null
                        ? Image.network(
                            trip.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              LucideIcons.image,
                              color: secondaryColor,
                              size: 24,
                            ),
                          )
                        : Icon(
                            LucideIcons.image,
                            color: secondaryColor,
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                // Trip Information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        trip.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Destination
                      if (trip.destino != null) ...[
                        _InfoRow(
                          icon: LucideIcons.mapPin,
                          label: trip.destino!,
                          color: secondaryColor,
                        ),
                        const SizedBox(height: 6),
                      ],
                      // Dates
                      _InfoRow(
                        icon: LucideIcons.calendar,
                        label: '${_formatDate(trip.dataIda)} - ${_formatDate(trip.dataVolta)}',
                        color: secondaryColor,
                      ),
                      if (trip.numPessoas != null) ...[
                        const SizedBox(height: 6),
                        _InfoRow(
                          icon: LucideIcons.users,
                          label: '${trip.numPessoas} ${trip.numPessoas == 1 ? 'pessoa' : 'pessoas'}',
                          color: secondaryColor,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 20,
                  color: secondaryColor.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}



