import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class DocumentosScreen extends StatelessWidget {
  const DocumentosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Documentos')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 64, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text('Seus documentos aparecerão aqui', style: TextStyle(color: AppColors.textSecondary)),
            SizedBox(height: 8),
            Text(
              'Roteiros, vouchers e comprovantes enviados pela Cadife Tour',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
