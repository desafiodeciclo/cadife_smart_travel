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

  Color _scoreColor(LeadScore score) {
    return switch (score) {
      LeadScore.quente => AppColors.success,
      LeadScore.morno => AppColors.warning,
      LeadScore.frio => AppColors.textSecondary,
    };
  }

  String _scoreLabel(LeadScore score) {
    return switch (score) {
      LeadScore.quente => 'Quente',
      LeadScore.morno => 'Morno',
      LeadScore.frio => 'Frio',
    };
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Score
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        trip.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.titleMedium?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _scoreColor(trip.score).withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.all(Radius.circular(6)),
                      ),
                      child: Text(
                        _scoreLabel(trip.score),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _scoreColor(trip.score),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Destination
                if (trip.destino != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          trip.destino!,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                // Dates
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_formatDate(trip.dataIda)} - ${_formatDate(trip.dataVolta)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                if (trip.numPessoas != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${trip.numPessoas} ${trip.numPessoas == 1 ? 'pessoa' : 'pessoas'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
