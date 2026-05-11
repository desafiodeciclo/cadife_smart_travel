import 'package:cadife_smart_travel/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

class SyncIndicator extends StatelessWidget {
  const SyncIndicator({
    required this.isSyncing,
    required this.isOffline,
    super.key,
    this.lastSyncedAt,
  });

  final bool isSyncing;
  final bool isOffline;
  final DateTime? lastSyncedAt;

  @override
  Widget build(BuildContext context) {
    if (!isSyncing && !isOffline) return const SizedBox.shrink();

    if (isSyncing) {
      return Shimmer.fromColors(
        baseColor: AppColors.zinc300,
        highlightColor: AppColors.zinc100,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: AppColors.zinc200,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.refreshCw, size: 14, color: AppColors.zinc500),
              SizedBox(width: 8),
              Text(
                'Sincronizando itinerário...',
                style: TextStyle(fontSize: 12, color: AppColors.zinc500),
              ),
            ],
          ),
        ),
      );
    }

    // Offline banner
    final lastSync = lastSyncedAt;
    final lastSyncText = lastSync != null
        ? 'Última atualização: ${_formatRelative(lastSync)}'
        : 'Sem dados sincronizados';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: AppColors.warning,
      child: Row(
        children: [
          const Icon(LucideIcons.wifiOff, size: 14, color: AppColors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Modo offline — $lastSyncText',
              style: const TextStyle(fontSize: 12, color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min atrás';
    if (diff.inHours < 24) return '${diff.inHours}h atrás';
    return DateFormat('dd/MM HH:mm').format(dt);
  }
}
