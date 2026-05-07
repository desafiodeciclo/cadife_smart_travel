import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/offers/domain/entities/offer.dart';
import 'package:flutter/material.dart';

class OfferCard extends StatelessWidget {
  final Offer offer;
  final VoidCallback? onTap;

  const OfferCard({
    required this.offer,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final formattedPrice = currencyFormatter.format(offer.estimatedPrice);
    final theme = ShadTheme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.border),
          color: theme.colorScheme.background,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem e Badge de Categoria
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Hero(
                    tag: 'offer_hero_${offer.id}',
                    child: Image.network(
                      offer.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: theme.colorScheme.border,
                          child: Center(
                            child: Icon(Icons.image_not_supported, color: theme.colorScheme.mutedForeground),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      offer.category,
                      style: theme.textTheme.small.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Informações
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Destino
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: theme.colorScheme.mutedForeground),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            offer.destination,
                            style: theme.textTheme.small.copyWith(
                              color: theme.colorScheme.mutedForeground,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Título
                    Text(
                      offer.title,
                      style: theme.textTheme.p.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    
                    // Preço
                    Row(
                      children: [
                        Text(
                          'A partir de',
                          style: theme.textTheme.small.copyWith(
                            color: AppColors.zinc500,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      formattedPrice,
                      style: theme.textTheme.h4.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
