import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/status/domain/entities/checkpoint_item.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


/// Ordered list of all 7 travel milestones.
/// Activated checkpoints show a coloured icon + timestamp; pending ones are grey.
class TravelCheckpointTimeline extends StatelessWidget {
  const TravelCheckpointTimeline({required this.activated, super.key});

  final List<CheckpointItem> activated;

  static const _all = TravelCheckpointType.values;

  static const _icons = <TravelCheckpointType, IconData>{
    TravelCheckpointType.briefingColetado: Icons.assignment_turned_in_outlined,
    TravelCheckpointType.curadoriaIniciada: Icons.support_agent_outlined,
    TravelCheckpointType.propostaEnviada: Icons.send_outlined,
    TravelCheckpointType.propostaAprovada: Icons.thumb_up_alt_outlined,
    TravelCheckpointType.viagemConfirmada: Icons.check_circle_outline,
    TravelCheckpointType.viagemEmAndamento: Icons.flight_takeoff_outlined,
    TravelCheckpointType.viagemConcluida: Icons.flag_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final activatedMap = {for (final c in activated) c.checkpoint: c};
    final fmt = DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROGRESSO DA VIAGEM',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: cadife.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _all.length,
          itemBuilder: (context, index) {
            final type = _all[index];
            final item = activatedMap[type];
            final isActivated = item != null;
            final isLast = index == _all.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 36,
                    child: Column(
                      children: [
                        _Dot(
                          icon: _icons[type]!,
                          isActivated: isActivated,
                          activeColor: cadife.primary,
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: isActivated
                                  ? cadife.primary.withValues(alpha: 0.3)
                                  : cadife.textSecondary.withValues(alpha: 0.15),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isActivated
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isActivated
                                  ? cadife.textPrimary
                                  : cadife.textSecondary,
                            ),
                          ),
                          if (item != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              fmt.format(item.ativadoEm.toLocal()),
                              style: TextStyle(
                                fontSize: 11,
                                color: cadife.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.icon,
    required this.isActivated,
    required this.activeColor,
  });

  final IconData icon;
  final bool isActivated;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActivated ? activeColor : Colors.grey.shade200,
      ),
      child: Icon(
        icon,
        size: 18,
        color: isActivated ? Colors.white : Colors.grey.shade400,
      ),
    );
  }
}
