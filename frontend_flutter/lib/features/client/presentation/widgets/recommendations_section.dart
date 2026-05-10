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
              'Baseado no seu Perfil',
              style: TextStyle(
                color: cadife.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
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
        const SizedBox(height: 16),
        SizedBox(
          height: 300, // Height for the offer cards
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: recommendations.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final rec = recommendations[index];
              return SizedBox(
                width: screenWidth * 0.75,
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
