import 'package:cadife_smart_travel/features/client/itinerary/domain/entities/itinerary_item.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ItineraryCard extends StatelessWidget {
  const ItineraryCard({
    required this.item,
    super.key,
    this.onNoteTap,
  });

  final ItineraryItem item;
  final VoidCallback? onNoteTap;

  @override
  Widget build(BuildContext context) {
    final color = item.tipo.color;
    final timeFmt = DateFormat('HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícone do tipo
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.tipo.icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),

            // Conteúdo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.tipo.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _buildTimeRange(timeFmt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5D6D7E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.titulo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  if (item.descricao != null && item.descricao!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.descricao!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5D6D7E),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (item.local != null && item.local!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.mapPin,
                          size: 12,
                          color: Color(0xFF5D6D7E),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.local!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5D6D7E),
                            ),
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
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.stickyNote,
                            size: 12,
                            color: Color(0xFF5D6D7E),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.notas!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF5D6D7E),
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
        ),
      ),
    );
  }

  String _buildTimeRange(DateFormat fmt) {
    final start = fmt.format(item.dataHora.toLocal());
    if (item.dataHoraFim == null) return start;
    final end = fmt.format(item.dataHoraFim!.toLocal());
    return '$start – $end';
  }
}
