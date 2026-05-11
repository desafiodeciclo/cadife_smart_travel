import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/offers/domain/entities/offer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    final currencyFormatter =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final formattedPrice = currencyFormatter.format(offer.estimatedPrice);
    final cadife = context.cadife;

    return CadifeCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagem e Badge de Categoria
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.3, // Mais horizontal para caber no widget menor
                child: Hero(
                  tag: 'offer_hero_${offer.id}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      offer.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: cadife.muted,
                          child: Center(
                            child: Icon(Icons.image_not_supported,
                                color: cadife.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: cadife.primary,
                    borderRadius: BorderRadius.circular(20), // Pill shape
                  ),
                  child: Text(
                    offer.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Informações
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Destino
                Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: cadife.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        offer.destination,
                        style: TextStyle(
                          color: cadife.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Título
                Text(
                  offer.title,
                  style: TextStyle(
                    color: cadife.textPrimary,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Preço
                Text(
                  'A partir de',
                  style: TextStyle(
                    color: cadife.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedPrice,
                  style: TextStyle(
                    color: cadife.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
