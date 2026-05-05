import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';

class OngoingTripCard extends StatelessWidget {
  const OngoingTripCard({
    super.key,
    this.destination = 'Paris, França',
    this.date = '15 Out 2024',
    this.time = '20:45',
    this.imageUrl,
    this.onTap,
  });

  final String destination;
  final String date;
  final String time;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 200,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _TripBackground(imageUrl: imageUrl),
                // Dark gradient so bottom text is always readable
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, AppColors.overlayDark],
                      stops: [0.35, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProximaViagemTag(),
                      const Spacer(),
                      Text(
                        destination,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            date,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.access_time_outlined,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            time,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProximaViagemTag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShadBadge(
      backgroundColor: Theme.of(context).colorScheme.primary,
      hoverBackgroundColor: Theme.of(context).colorScheme.primary,
      child: const Text('Próxima Viagem'),
    );
  }
}

class _TripBackground extends StatelessWidget {
  const _TripBackground({this.imageUrl});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Hero(
        tag: 'ongoing_trip_image',
        child: Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const _FallbackGradient(),
        ),
      );
    }
    return const _FallbackGradient();
  }
}

class _FallbackGradient extends StatelessWidget {
  const _FallbackGradient();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.fallbackNavyLight, AppColors.fallbackNavyDark],
        ),
      ),
    );
  }
}
