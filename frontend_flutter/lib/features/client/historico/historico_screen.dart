import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class HistoricoScreen extends StatelessWidget {
  const HistoricoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 64, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text('Histórico de interações', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
