import 'package:cadife_smart_travel/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum LeadScoreBadge { quente, morno, frio }

class ScoreBadge extends StatelessWidget {
  final LeadScoreBadge score;
  final bool showLabel;

  const ScoreBadge({
    required this.score,
    super.key,
    this.showLabel = true,
  });

  Color get _color => switch (score) {
        LeadScoreBadge.quente => AppColors.scoreQuente,
        LeadScoreBadge.morno  => AppColors.scoreMorno,
        LeadScoreBadge.frio   => AppColors.scoreFrio,
      };

  String get _label => switch (score) {
        LeadScoreBadge.quente => 'Quente',
        LeadScoreBadge.morno  => 'Morno',
        LeadScoreBadge.frio   => 'Frio',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              _label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
