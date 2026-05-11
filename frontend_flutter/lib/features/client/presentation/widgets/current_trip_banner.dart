// lib/features/client/presentation/widgets/current_trip_banner.dart

import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/home/domain/entities/client_trip.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CurrentTripBanner extends StatelessWidget {
  final ClientTrip trip;

  const CurrentTripBanner({required this.trip, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pushNamed(
        'client_trip_details',
        pathParameters: {'tripId': trip.id},
      ),
      child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            height: 240,
            width: double.infinity,
            child: Stack(
              children: [
                // Imagem de fundo
                Positioned.fill(
                  child: Hero(
                    tag: 'trip_banner_${trip.id}',
                    child: Image.network(
                      trip.coverImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.zinc300,
                        child: const Center(
                          child: Icon(
                            Icons.landscape,
                            size: 48,
                            color: AppColors.zinc500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Gradient overlay inferior
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                        stops: [0.4, 1.0],
                      ),
                    ),
                  ),
                ),
                // Conteúdo no rodapé do banner
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              trip.destinationFlag,
                              style: const TextStyle(fontSize: 28),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trip.destination,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 4,
                                        color: Colors.black45,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  trip.destinationCountry,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 13,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${trip.startDate.day}/${trip.startDate.month}'
                              ' — '
                              '${trip.endDate.day}/${trip.endDate.month}/${trip.endDate.year}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}
