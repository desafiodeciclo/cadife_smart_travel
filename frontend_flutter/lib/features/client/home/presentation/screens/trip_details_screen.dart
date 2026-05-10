import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/home/infrastructure/mocks/client_home_mocks.dart';
import 'package:cadife_smart_travel/features/client/itinerary/presentation/providers/itinerary_provider.dart';
import 'package:cadife_smart_travel/features/client/itinerary/presentation/widgets/itinerary_card.dart';
import 'package:cadife_smart_travel/features/client/presentation/widgets/documents_section.dart';
import 'package:cadife_smart_travel/features/client/presentation/widgets/trip_status_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TripDetailsScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripDetailsScreen({required this.tripId, super.key});

  @override
  ConsumerState<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends ConsumerState<TripDetailsScreen> {
  bool _isPopping = false;

  void _handleBack() {
    if (_isPopping) return;
    
    if (mounted) {
      setState(() => _isPopping = true);
      // Garantimos que o "direcionamento" seja para a tela principal de status
      context.go('/client/status');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final itineraryState = ref.watch(itineraryProvider(widget.tripId));
    // Em um cenário real, buscaríamos a viagem pelo ID
    final trip = ClientHomeMocks.mockCurrentTrip();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: cadife.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header com imagem e Hero
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black45,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  onPressed: _handleBack,
                  tooltip: 'Voltar',
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'trip_banner_${trip.id}',
                    child: Image.network(
                      trip.coverImageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: AppColors.zinc800,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white24,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.zinc800,
                        child: const Center(
                          child: Icon(
                            Icons.landscape,
                            size: 64,
                            color: Colors.white24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black45,
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black87,
                        ],
                        stops: [0.0, 0.3, 0.6, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              trip.destinationFlag,
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    trip.destination,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Text(
                                    trip.destinationCountry,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
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

          // Conteúdo
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: cadife.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    // Datas e Duração
                    Row(
                      children: [
                        _buildInfoBadge(
                          context,
                          Icons.calendar_month_outlined,
                          '${trip.startDate.day}/${trip.startDate.month} - ${trip.endDate.day}/${trip.endDate.month}',
                          'Data da Viagem',
                          onTap: () => context.pushNamed('client_travel_calendar', pathParameters: {'tripId': widget.tripId}),
                        ),
                        const SizedBox(width: 12),
                        _buildInfoBadge(
                          context,
                          Icons.timer_outlined,
                          '${trip.endDate.difference(trip.startDate).inDays} dias',
                          'Duração',
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Seção de Status
                    TripStatusSection(trip: trip),

                    const SizedBox(height: 32),

                    // Itinerário da Viagem (NOVA SEÇÃO)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ITINERÁRIO',
                          style: TextStyle(
                            color: cadife.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.pushNamed('client_travel_calendar', pathParameters: {'tripId': widget.tripId}),
                          child: Text(
                            'Ver tudo',
                            style: TextStyle(
                              color: cadife.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    if (itineraryState.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (itineraryState.items.isEmpty)
                      CadifeGlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'Itinerário ainda não disponível',
                            style: TextStyle(color: cadife.textSecondary),
                          ),
                        ),
                      )
                    else
                      ...itineraryState.items.take(3).map((item) => ItineraryCard(
                        key: ValueKey('itinerary_item_${item.id}'),
                        item: item,
                      )),

                    const SizedBox(height: 32),

                    // Documentos dessa viagem
                    DocumentsSection(documents: ClientHomeMocks.mockDocuments()),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(BuildContext context, IconData icon, String value, String label, {VoidCallback? onTap}) {
    final cadife = context.cadife;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: CadifeGlassCard(
          padding: const EdgeInsets.all(12),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: cadife.primary),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: cadife.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: cadife.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
