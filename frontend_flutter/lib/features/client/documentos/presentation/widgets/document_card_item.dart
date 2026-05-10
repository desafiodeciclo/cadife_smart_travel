import 'package:cadife_smart_travel/design_system/tokens/app_colors.dart';
import 'package:cadife_smart_travel/features/client/documentos/domain/entities/documento.dart';
import 'package:cadife_smart_travel/features/client/documentos/presentation/widgets/document_icon.dart';
import 'package:flutter/material.dart';

class DocumentCardItem extends StatelessWidget {
  const DocumentCardItem({
    required this.documentName,
    required this.documentType,
    required this.fileSize,
    required this.onTap,
    super.key,
  });

  final String documentName;
  final DocumentType documentType;
  final String fileSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground;
    final border = isDark ? AppColors.borderColorDark : AppColors.borderColor;
    final textColor = isDark ? AppColors.white : AppColors.textPrimary;
    final subColor = isDark ? AppColors.zinc400 : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: surface,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            DocumentIcon(type: documentType, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    documentName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    fileSize,
                    style: TextStyle(fontSize: 11, color: subColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: subColor),
          ],
        ),
      ),
    );
  }
}
