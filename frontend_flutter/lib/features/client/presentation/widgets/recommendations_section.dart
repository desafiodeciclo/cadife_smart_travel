// lib/features/client/presentation/widgets/recommendations_section.dart

import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/offers/domain/entities/offer.dart';
import 'package:cadife_smart_travel/features/client/offers/presentation/widgets/offer_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RecommendationsSection extends StatelessWidget {
  final List<Offer> recommendations;

  const RecommendationsSection({required this.recommendations, super.key});

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BASEADO NO SEU PERFIL',
              style: TextStyle(
                color: cadife.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            GestureDetector(
              onTap: () => context.pushNamed('client_offers'),
              child: Text(
                'Ver todos',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cadife.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 280, // Reduzido ainda mais
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: recommendations.length, // Mostrar todos no carrossel
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final rec = recommendations[index];
              return SizedBox(
                width: screenWidth * 0.45, // Reduzido de 0.50 para 0.45
                child: OfferCard(
                  offer: rec,
                  onTap: () {
                    context.pushNamed(
                      'client_offer_details',
                      pathParameters: {'offerId': rec.id},
                      extra: rec,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
