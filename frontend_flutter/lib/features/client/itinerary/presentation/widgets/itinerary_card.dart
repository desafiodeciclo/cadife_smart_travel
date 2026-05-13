import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/itinerary/domain/entities/itinerary_item.dart';
import 'package:flutter/material.dart';


class ItineraryCard extends StatelessWidget {
  const ItineraryCard({
    required this.item,
    super.key,
    this.onNoteTap,
    this.showBorder = true,
    this.showCard = true,
  });

  final ItineraryItem item;
  final VoidCallback? onNoteTap;
  final bool showBorder;
  final bool showCard;

  @override
  Widget build(BuildContext context) {
    final color = item.tipo.color;
    final timeFmt = DateFormat('HH:mm');
    final cadife = context.cadife;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final innerContent = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(item.tipo.icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.tipo.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _buildTimeRange(timeFmt),
                    style: TextStyle(
                      fontSize: 12,
                      color: cadife.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                item.titulo,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.zinc50 : AppColors.zinc950,
                ),
              ),
              if (item.descricao != null && item.descricao!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  item.descricao!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.zinc400 : AppColors.zinc600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (item.local != null && item.local!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(LucideIcons.mapPin, size: 12, color: cadife.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.local!,
                        style: TextStyle(fontSize: 12, color: cadife.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (item.notas != null && item.notas!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cadife.muted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.stickyNote, size: 12, color: cadife.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.notas!,
                          style: TextStyle(
                            fontSize: 11,
                            color: cadife.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    if (!showCard) {
      return Padding(padding: const EdgeInsets.all(12), child: innerContent);
    }

    final bg = isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground;
    return CadifeCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 16,
      color: bg,
      showBorder: showBorder,
      child: innerContent,
    );
  }

  String _buildTimeRange(DateFormat fmt) {
    final start = fmt.format(item.dataHora.toLocal());
    if (item.dataHoraFim == null) return start;
    final end = fmt.format(item.dataHoraFim!.toLocal());
    return '$start – $end';
  }
}
