import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/status/data/mocks/client_home_mocks.dart';
import 'package:cadife_smart_travel/features/client/status/presentation/widgets/consultant_contact_card.dart';
import 'package:cadife_smart_travel/features/client/status/presentation/widgets/current_trip_banner.dart';
import 'package:cadife_smart_travel/features/client/status/presentation/widgets/documents_carousel.dart';
import 'package:cadife_smart_travel/features/client/status/presentation/widgets/recommendations_section.dart';
import 'package:cadife_smart_travel/features/client/status/presentation/widgets/trip_status_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

const _kAyaWhatsApp = '5511999999999';

class StatusPage extends ConsumerWidget {
  const StatusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ClientHomeMocks.homeData();

    return PageScaffold(
      title: 'Minha Viagem',
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () => context.push('/notifications'),
          tooltip: 'Notificações',
        ),
      ],
      floatingActionButton: _AyaFab(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(top: 72, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CurrentTripBanner(data: data),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TripStatusSection(data: data),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ConsultantContactCard(consultant: data.consultant),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: DocumentsCarousel(
                  documents: data.documents,
                  tripId: data.tripId,
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: RecommendationsSection(
                  recommendations: data.recommendations,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AyaFab extends StatelessWidget {
  Future<void> _launch() async {
    final uri = Uri.parse(
      'https://wa.me/$_kAyaWhatsApp'
      '?text=Olá!%20Gostaria%20de%20continuar%20meu%20atendimento.',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: _launch,
      backgroundColor: const Color(0xFF25D366),
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.chat_bubble_outline_rounded),
      label: const Text(
        'Chat AYA',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
