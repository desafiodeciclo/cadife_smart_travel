import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';

class DateDivider extends StatelessWidget {
  const DateDivider({super.key, required this.date});
  final DateTime date;

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    
    if (d == today) return 'Hoje';
    if (d == yesterday) return 'Ontem';
    return DateFormat("d 'de' MMMM", 'pt_BR').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _label(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: context.cadife.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}
