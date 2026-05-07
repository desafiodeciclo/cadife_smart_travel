import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/status/domain/entities/home_page_data.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RecommendationsSection extends StatelessWidget {
  const RecommendationsSection({required this.recommendations, super.key});

  final List<TravelRecommendation> recommendations;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Baseado no seu Perfil',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cadife.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/client/offers'),
              child: Text(
                'Ver ofertas',
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
        ...recommendations.map(
          (rec) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _RecommendationCard(recommendation: rec),
          ),
        ),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.recommendation});

  final TravelRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;

    return GestureDetector(
      onTap: () => context.push('/client/offers'),
      child: CadifeGlassCard(
        blur: 20,
        opacity: 0.07,
        borderRadius: BorderRadius.circular(20),
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: _RecommendationImage(title: recommendation.title),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          recommendation.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: cadife.textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: cadife.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    recommendation.destination,
                    style: TextStyle(
                      fontSize: 12,
                      color: cadife.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    recommendation.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: cadife.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: recommendation.reasons.map((r) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cadife.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cadife.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          r,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: cadife.primary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 15, color: Colors.amber),
                      const SizedBox(width: 3),
                      Text(
                        recommendation.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cadife.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${recommendation.numberOfReviews})',
                        style: TextStyle(
                          fontSize: 12,
                          color: cadife.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationImage extends StatelessWidget {
  const _RecommendationImage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.fallbackNavyLight, AppColors.fallbackNavyDark],
        ),
      ),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
