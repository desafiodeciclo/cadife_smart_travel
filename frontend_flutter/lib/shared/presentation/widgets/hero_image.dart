import 'package:cadife_smart_travel/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';
/// Widget wrapper que encapsula lógica de Hero com validações
class HeroImage extends StatelessWidget {
  final String heroTag;
  final String imageUrl;
  final double height;
  final double? width;
  final BoxFit fit;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  
  const HeroImage({
    required this.heroTag,
    required this.imageUrl,
    required this.height,
    super.key,
    this.width,
    this.fit = BoxFit.cover,
    this.onTap,
    this.borderRadius,
  });
  
  @override
  Widget build(BuildContext context) {
    final child = GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: heroTag,
        transitionOnUserGestures: true,
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(20),
          child: Image.network(
            imageUrl,
            height: height,
            width: width,
            fit: fit,
            errorBuilder: (_, _, _) => Container(
              height: height,
              width: width,
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.image_not_supported),
              ),
            ),
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Container(
                height: height,
                width: width,
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    
    return child;
  }
}
