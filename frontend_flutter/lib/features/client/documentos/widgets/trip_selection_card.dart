import 'package:cadife_smart_travel/core/theme/app_colors.dart';
import 'package:cadife_smart_travel/shared/models/lead_model.dart';
import 'package:flutter/material.dart';

class TripSelectionCard extends StatelessWidget {
  const TripSelectionCard({
    super.key,
    required this.trip,
    this.onTap,
  });

  final LeadModel trip;
  final VoidCallback? onTap;

  String _formatDate(DateTime? date) {
    if (date == null) return '--/--/--';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? (isDark ? AppColors.darkCard : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trip Illustration Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: theme.dividerColor.withValues(alpha: 0.1),
                    child: trip.imageUrl != null
                        ? Image.network(
                            trip.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.image_outlined,
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3),
                            ),
                          )
                        : Icon(
                            Icons.image_outlined,
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3),
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
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: theme.textTheme.titleMedium?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Destination
                      if (trip.destino != null) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                trip.destino!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      // Dates
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatDate(trip.dataIda)} - ${_formatDate(trip.dataVolta)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      if (trip.numPessoas != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 14,
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${trip.numPessoas} ${trip.numPessoas == 1 ? 'pessoa' : 'pessoas'}',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
