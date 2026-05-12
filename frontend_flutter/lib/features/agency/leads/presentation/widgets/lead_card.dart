import 'package:cadife_smart_travel/core/utils/extensions/extensions.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/hero_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LeadCard extends StatelessWidget {
  const LeadCard({required this.lead, super.key});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final statusColor = AppColors.statusColor(lead.status.name);
    final scoreColor = AppColors.scoreColor(lead.score.name);
    final borderColor = isDark ? Colors.white10 : context.cadife.cardBorder;
    final dividerColor = isDark ? Colors.white10 : context.cadife.cardBorder;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ShadCard(
        padding: EdgeInsets.zero,
        backgroundColor: context.cadife.cardBackground,
        radius: BorderRadius.circular(12),
        border: ShadBorder.all(color: borderColor, width: 1),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.go('/agency/leads/${lead.id}'),
            child: Stack(
              children: [
                // Borda lateral colorida por status
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (lead.imageUrl != null) ...[
                        HeroImage(
                          heroTag: 'lead_image_${lead.id}',
                          imageUrl: lead.imageUrl!,
                          height: 120,
                          width: double.infinity,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lead.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          LeadStatusBadge(status: lead.status, color: statusColor),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined,
                              size: 13, color: context.cadife.textSecondary),
                          const SizedBox(width: 5),
                          Text(
                            lead.phone,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.cadife.textSecondary,
                            ),
                          ),
                          if (lead.perfil != null) ...[
                            const SizedBox(width: 10),
                            Icon(Icons.people_outline,
                                size: 13, color: context.cadife.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              lead.perfil!,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.cadife.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Divider(height: 1, color: dividerColor),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.flight_takeoff,
                              size: 13, color: context.cadife.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              lead.destino ?? 'Destino a definir',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.cadife.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (lead.dataIda != null) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.calendar_today_outlined,
                                size: 12, color: context.cadife.textSecondary),
                            const SizedBox(width: 3),
                            Text(
                              lead.dataIda!.toDateString(),
                              style: TextStyle(
                                fontSize: 11,
                                color: context.cadife.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(width: 10),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _scoreIcon(lead.score),
                                size: 13,
                                color: scoreColor,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                lead.score.name.capitalized,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: scoreColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: lead.completudePct / 100,
                                minHeight: 4,
                                backgroundColor: context.cadife.cardBorder,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  lead.completudePct >= 80
                                      ? AppColors.success
                                      : lead.completudePct >= 50
                                          ? AppColors.warning
                                          : context.cadife.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${lead.completudePct}%',
                            style: TextStyle(
                              fontSize: 11,
                              color: context.cadife.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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

  IconData _scoreIcon(LeadScore score) => switch (score) {
        LeadScore.quente => Icons.local_fire_department,
        LeadScore.morno => Icons.thermostat,
        LeadScore.frio => Icons.ac_unit,
      };
}

class LeadStatusBadge extends StatelessWidget {
  const LeadStatusBadge({required this.status, required this.color, super.key});

  final LeadStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ShadBadge(
      backgroundColor: color.withValues(alpha: 0.10),
      foregroundColor: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(status.name.sentenceCase),
    );
  }
}
