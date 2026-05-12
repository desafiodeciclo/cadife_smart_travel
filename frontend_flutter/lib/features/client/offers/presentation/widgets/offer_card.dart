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
    final currencyFormatter =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final formattedPrice = currencyFormatter.format(offer.finalPrice);
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
                aspectRatio: 1.3,
                child: Hero(
                  tag: 'offer_hero_${offer.id}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      offer.destinationImageUrl ?? '',
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
              // Badge de categoria
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cadife.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    offer.category ?? 'Viagem',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              // Badge de desconto
              if (offer.hasDiscount)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '-${offer.discountPercent.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              // Overlay de vagas esgotadas
              if (!offer.availableSpot)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: const Center(
                        child: Text(
                          'VAGAS\nESGOTADAS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
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
