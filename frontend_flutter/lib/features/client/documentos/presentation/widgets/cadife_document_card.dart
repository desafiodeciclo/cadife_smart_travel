import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/documentos/domain/entities/documento.dart';
import 'package:cadife_smart_travel/features/client/documentos/presentation/widgets/document_icon.dart';
import 'package:flutter/material.dart';

class CadifeDocumentCard extends StatelessWidget {
  const CadifeDocumentCard({
    required this.document,
    super.key,
    this.onView,
    this.onDownload,
    this.padding,
  });

  final Documento document;
  final VoidCallback? onView;
  final VoidCallback? onDownload;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cadife.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: cadife.cardBorder,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Document Icon
            DocumentIcon(type: document.type, size: 28),
            const SizedBox(width: 16),
            
            // Document Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (document.category != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        document.category!.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    document.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: cadife.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    document.sizeFormatted,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: cadife.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            
            // Action Buttons stacked vertically
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionButton(
                  label: 'VER',
                  onPressed: onView,
                  isPrimary: true,
                ),
                const SizedBox(height: 8),
                _ActionButton(
                  label: 'BAIXAR',
                  icon: LucideIcons.download,
                  onPressed: onDownload,
                  isPrimary: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const _ActionButton({
    required this.label,
    required this.isPrimary,
    this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryButtonColor = isDark ? Colors.white : Colors.black;
    final secondaryButtonColor = isDark ? Colors.white : Colors.black;

    return SizedBox(
      height: 38,
      width: 85,
      child: isPrimary
          ? ShadButton(
              onPressed: onPressed,
              backgroundColor: primaryButtonColor,
              foregroundColor: isDark ? Colors.black : Colors.white,
              decoration: ShadDecoration(
                border: ShadBorder.all(
                  radius: BorderRadius.circular(10),
                ),
              ),
              padding: EdgeInsets.zero,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            )
          : ShadButton.outline(
              onPressed: onPressed,
              backgroundColor: Colors.transparent,
              foregroundColor: secondaryButtonColor,
              decoration: ShadDecoration(
                border: ShadBorder.all(
                  color: cadife.cardBorder,
                  width: 1,
                  radius: BorderRadius.circular(10),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              leading: icon != null ? Icon(icon, size: 14) : null,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
    );
  }
}



