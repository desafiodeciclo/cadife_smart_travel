import 'dart:ui';

import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/itinerary/domain/entities/itinerary_item.dart';
import 'package:flutter/material.dart';
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
    final cadife = context.cadife;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            constraints: const BoxConstraints(minHeight: 80),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.08 : 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border(
                left: BorderSide(color: color, width: 4),
                top: BorderSide(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
                right: BorderSide(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
                bottom: BorderSide(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.tipo.icon, size: 20, color: color),
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
                                color: color.withValues(alpha: 0.15),
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
                            color: cadife.textPrimary,
                          ),
                        ),
                        if (item.descricao != null && item.descricao!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            item.descricao!,
                            style: TextStyle(
                              fontSize: 12,
                              color: cadife.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (item.local != null && item.local!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                LucideIcons.mapPin,
                                size: 12,
                                color: cadife.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.local!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cadife.textSecondary,
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
                              color: cadife.muted.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.stickyNote,
                                  size: 12,
                                  color: cadife.textSecondary,
                                ),
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
              ),
            ),
          ),
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
