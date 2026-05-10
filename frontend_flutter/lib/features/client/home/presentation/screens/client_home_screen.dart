import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/home/infrastructure/mocks/client_home_mocks.dart';
import 'package:cadife_smart_travel/features/client/presentation/widgets/consultant_contact_card.dart';
import 'package:cadife_smart_travel/features/client/presentation/widgets/current_trip_banner.dart';
import 'package:cadife_smart_travel/features/client/presentation/widgets/documents_section.dart';
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
      title: 'Minha Viagem',
      actions: [
        const NotificationBell(),
      ],
      body: Builder(
        builder: (context) {
          final topPad = MediaQuery.of(context).padding.top + kToolbarHeight;
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, topPad, 12, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CurrentTripBanner(trip: trip),
                  const SizedBox(height: 24),
                  TripStatusSection(trip: trip),
                  const SizedBox(height: 24),
                  ConsultantContactCard(consultant: consultant),
                  const SizedBox(height: 24),
                  DocumentsSection(documents: documents),
                  const SizedBox(height: 24),
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
