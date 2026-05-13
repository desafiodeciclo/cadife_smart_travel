import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/itinerary/domain/entities/itinerary_day.dart';
import 'package:cadife_smart_travel/features/client/itinerary/domain/entities/itinerary_item.dart';
import 'package:flutter/material.dart';

/// Widget reutilizável de roteiro.
/// [isCompact] true = mostra os 3 primeiros dias + botão "Ver completo".
/// [isCompact] false = todos os dias.
/// [onViewAll] callback do botão "Ver roteiro completo" (só usado em modo compacto).
class ItineraryWidget extends StatelessWidget {
  const ItineraryWidget({
    required this.days,
    this.isCompact = false,
    this.onViewAll,
    super.key,
  });

  final List<ItineraryDay> days;
  final bool isCompact;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final visible = isCompact ? days.take(3).toList() : days;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...visible.asMap().entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ItineraryDayCard(day: e.value, dayNumber: e.key + 1),
          );
        }),
        if (isCompact && days.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextButton.icon(
              onPressed: onViewAll,
              icon: const Icon(Icons.expand_more, size: 18),
              label: Text(
                'Ver itinerário completo (${days.length} dias)',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ItineraryDayCard extends StatelessWidget {
  const _ItineraryDayCard({required this.day, required this.dayNumber});

  final ItineraryDay day;
  final int dayNumber;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, dd/MM', 'pt_BR');
    final cadife = context.cadife;

    return CadifeCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 14,
      color: cadife.cardBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Dia $dayNumber',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dateFmt.format(day.data),
                style: AppTextStyles.bodySmall.copyWith(
                  color: cadife.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (day.itens.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            ...day.itens.map((item) => _ItemRow(item: item)),
          ],
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final ItineraryItem item;

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.tipo.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.tipo.icon, color: item.tipo.color, size: 20),
          ),
          const SizedBox(width: 10),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.titulo,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.cadife.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      timeFmt.format(item.dataHora),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.cadife.textSecondary,
                      ),
                    ),
                    if (item.local != null) ...[
                      Text(
                        ' · ',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.cadife.textSecondary,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          item.local!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.cadife.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
