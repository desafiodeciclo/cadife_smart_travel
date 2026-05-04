import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/historico/domain/entities/interacao.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.interaction});
  final Interacao interaction;

  bool get _isClient => interaction.direction == 'inbound';

  bool get _isAya =>
      interaction.direction == 'outbound' &&
      (interaction.channel == 'whatsapp' || interaction.channel == 'aya');

  Color get _bubbleColor {
    if (_isClient) return AppColors.surface;
    if (_isAya) return AppColors.primaryLight;
    return AppColors.bubbleConsultantLight;
  }

  Color get _textColor {
    if (_isClient) return AppColors.textPrimary;
    if (_isAya) return AppColors.primaryDark;
    return AppColors.bubbleConsultantDark;
  }

  Color get _senderColor => _isAya ? AppColors.primary : AppColors.info;

  String get _senderLabel =>
      _isAya ? 'AYA • Assistente' : 'Consultor Cadife';

  String _formatTimestamp(DateTime ts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(ts.year, ts.month, ts.day);
    final timeStr = DateFormat('HH:mm').format(ts);
    
    if (msgDate == today) return 'hoje às $timeStr';
    if (msgDate == yesterday) return 'ontem às $timeStr';
    return DateFormat("d MMM 'às' HH:mm", 'pt_BR').format(ts);
  }

  BorderRadius get _bubbleRadius => BorderRadius.only(
        topLeft: _isClient
            ? const Radius.circular(16)
            : const Radius.circular(4),
        topRight: _isClient
            ? const Radius.circular(4)
            : const Radius.circular(16),
        bottomLeft: const Radius.circular(16),
        bottomRight: const Radius.circular(16),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: _isClient ? 56 : 16,
        right: _isClient ? 16 : 56,
        bottom: 10,
      ),
      child: Column(
        crossAxisAlignment:
            _isClient ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!_isClient)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 3),
              child: Text(
                _senderLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _senderColor,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _bubbleColor,
              borderRadius: _bubbleRadius,
            ),
            child: Text(
              interaction.content,
              style: TextStyle(fontSize: 14.5, height: 1.45, color: _textColor),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
            child: Text(
              _formatTimestamp(interaction.timestamp),
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
