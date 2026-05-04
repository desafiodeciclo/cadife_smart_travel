import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/documentos/domain/entities/documento.dart';
import 'package:cadife_smart_travel/features/client/documentos/presentation/widgets/document_icon.dart';
import 'package:flutter/material.dart';

class CadifeDocumentCard extends StatelessWidget {
  const CadifeDocumentCard({
    super.key,
    required this.document,
    this.onView,
    this.onDownload,
  });

  final Documento document;
  final VoidCallback? onView;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.6);
    final surfaceColor = isDark ? context.cadife.cardBackground : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ShadCard(
        padding: const EdgeInsets.all(16),
        backgroundColor: surfaceColor,
        radius: BorderRadius.circular(16),
        border: ShadBorder.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
        child: InkWell(
          onTap: onView,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Document Icon Componentized
              DocumentIcon(type: document.type, size: 22),
              const SizedBox(width: 16),
              
              // Document Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (document.category != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          document.category!.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.black : Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      document.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      document.sizeFormatted,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              
              // Action Buttons
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
    this.icon,
    this.onPressed,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white : Colors.black;

    return SizedBox(
      height: 32,
      width: 80,
      child: isPrimary
          ? ShadButton(
              onPressed: onPressed,
              size: ShadButtonSize.sm,
              backgroundColor: color,
              foregroundColor: isDark ? Colors.black : Colors.white,
              decoration: ShadDecoration(
                border: ShadBorder.all(
                  radius: BorderRadius.circular(8),
                ),
              ),
              padding: EdgeInsets.zero,
              leading: icon != null ? Icon(icon, size: 12) : null,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          : ShadButton.outline(
              onPressed: onPressed,
              size: ShadButtonSize.sm,
              backgroundColor: Colors.transparent,
              foregroundColor: color,
              decoration: ShadDecoration(
                border: ShadBorder.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1,
                  radius: BorderRadius.circular(8),
                ),
              ),
              padding: EdgeInsets.zero,
              leading: icon != null ? Icon(icon, size: 12) : null,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
    );
  }
}



