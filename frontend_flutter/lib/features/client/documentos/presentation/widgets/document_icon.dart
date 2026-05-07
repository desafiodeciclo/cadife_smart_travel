import 'package:cadife_smart_travel/features/client/documentos/domain/entities/documento.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DocumentIcon extends StatelessWidget {
  final DocumentType type;
  final double size;
  final Color? color;
  final Color? backgroundColor;

  const DocumentIcon({
    required this.type,
    super.key,
    this.size = 24,
    this.color,
    this.backgroundColor,
  });

  IconData _getLucideIcon(DocumentType type) {
    return switch (type) {
      DocumentType.pdf => LucideIcons.fileText,
      DocumentType.image => LucideIcons.image,
      DocumentType.video => LucideIcons.video,
      DocumentType.audio => LucideIcons.music,
      DocumentType.other => LucideIcons.file,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Monochromatic Black Logic for Premium feel
    final effectiveBgColor = backgroundColor ?? (isDark 
        ? Colors.white.withValues(alpha: 0.1) 
        : Colors.black.withValues(alpha: 0.05));
    
    final effectiveIconColor = color ?? (isDark 
        ? Colors.white 
        : Colors.black);

    final typeLabel = switch (type) {
      DocumentType.pdf => 'PDF',
      DocumentType.image => 'IMG',
      DocumentType.video => 'VID',
      DocumentType.audio => 'AUD',
      DocumentType.other => 'DOC',
    };

    return Stack(
      children: [
        Container(
          width: size * 2,
          height: size * 2,
          decoration: BoxDecoration(
            color: effectiveBgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getLucideIcon(type),
            color: effectiveIconColor,
            size: size,
          ),
        ),
        Positioned(
          bottom: 2,
          right: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: isDark ? Colors.white : Colors.black,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              typeLabel,
              style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.black : Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
