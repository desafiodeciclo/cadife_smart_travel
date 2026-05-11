import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/home/infrastructure/mocks/client_home_mocks.dart';
import 'package:cadife_smart_travel/features/client/presentation/widgets/consultant_contact_card.dart';
import 'package:cadife_smart_travel/features/client/presentation/widgets/current_trip_banner.dart';
import 'package:cadife_smart_travel/features/client/presentation/widgets/documents_section.dart';
import 'package:cadife_smart_travel/features/client/presentation/widgets/itinerary_preview_section.dart';
import 'package:cadife_smart_travel/features/client/presentation/widgets/recommendations_section.dart';
import 'package:cadife_smart_travel/features/client/presentation/widgets/trip_status_section.dart';
import 'package:cadife_smart_travel/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClientHomeScreen extends ConsumerWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ClientHomeMocks.mockCurrentTrip();
    final consultant = ClientHomeMocks.mockConsultant();
    final documents = ClientHomeMocks.mockDocuments();
    final recommendations = ClientHomeMocks.mockRecommendations();

    return PageScaffold(
      showProfile: false, // Perfil agora no leading da AppBar
      appBar: const CadifeAppBar(
        title: 'INICIO',
        showProfile: true,
        actions: [
          NotificationBell(),
          SizedBox(width: 8),
        ],
      ),
      body: Builder(
        builder: (context) {
          const topPad = kToolbarHeight;
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, topPad, 12, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Banner da viagem atual
                  CurrentTripBanner(trip: trip),
                  const SizedBox(height: 24),

                  // 2. Status da viagem
                  TripStatusSection(trip: trip),
                  const SizedBox(height: 24),

                  // 3. Documentos
                  DocumentsSection(documents: documents),
                  const SizedBox(height: 24),

                  // 4. Itinerário (preview das próximas atividades)
                  ItineraryPreviewSection(tripId: trip.id),
                  const SizedBox(height: 24),

                  // 5. Consultor
                  ConsultantContactCard(consultant: consultant),
                  const SizedBox(height: 24),

                  // 6. Ofertas baseadas no perfil
                  RecommendationsSection(recommendations: recommendations),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
