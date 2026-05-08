import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/status/data/mocks/client_home_mocks.dart';
import 'package:cadife_smart_travel/features/client/status/domain/entities/client_travel_status.dart';
import 'package:cadife_smart_travel/features/client/status/presentation/providers/status_notifier.dart';
import 'package:cadife_smart_travel/features/client/status/presentation/providers/status_providers.dart';
import 'package:cadife_smart_travel/features/client/status/presentation/widgets/consultant_contact_card.dart';
import 'package:cadife_smart_travel/features/client/status/presentation/widgets/current_trip_banner.dart';
import 'package:cadife_smart_travel/features/client/status/presentation/widgets/documents_carousel.dart';
import 'package:cadife_smart_travel/features/client/status/presentation/widgets/recommendations_section.dart';
import 'package:cadife_smart_travel/features/client/status/presentation/widgets/status_stepper_widget.dart';
import 'package:cadife_smart_travel/features/client/status/presentation/widgets/trip_status_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

const _kAyaWhatsApp = '5511999999999';

class StatusPage extends ConsumerWidget {
  const StatusPage({this.tripId, super.key});

  final String? tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cadife = context.cadife;

    final statusAsync = tripId != null
        ? ref.watch(statusProvider(tripId!))
        : ref.watch(activeLeadProvider);

    return PageScaffold(
      title: tripId != null ? 'DETALHES DA VIAGEM' : 'MINHA VIAGEM',
      body: statusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro ao carregar status: $err')),
        data: (status) {
          if (status == null) {
            return const Center(child: Text('Nenhuma viagem encontrada.'));
          }

          final data = ClientHomeMocks.homeData();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(top: 72, bottom: 40),
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
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ShadButton.outline(
                      onPressed: () => _navigateToCalendar(context, status.id),
                      leading: const Icon(LucideIcons.calendar, size: 16),
                      child: const Text('Ver Itinerario'),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sua Jornada',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: cadife.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        StatusStepperWidget(
                            currentStep: _mapStatusToStep(status.status)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ConsultantContactCard(consultant: data.consultant),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: _AyaChatField(),
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
          );
        },
      ),
    );
  }

  int _mapStatusToStep(TravelStatus status) {
    switch (status) {
      case TravelStatus.emAtendimento:
      case TravelStatus.qualificado:
      case TravelStatus.agendado:
        return 0;
      case TravelStatus.proposta:
        return 1;
      case TravelStatus.confirmado:
        return 2;
    }
  }

  void _navigateToCalendar(BuildContext context, String leadId) {
    context.pushNamed(
      'client_travel_calendar',
      pathParameters: {'leadId': leadId},
    );
  }
}

class _AyaChatField extends StatelessWidget {
  const _AyaChatField();

  Future<void> _launch() async {
    final uri = Uri.parse(
      'https://wa.me/$_kAyaWhatsApp'
      '?text=Ola!%20Gostaria%20de%20continuar%20meu%20atendimento.',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;

    return GestureDetector(
      onTap: _launch,
      child: CadifeGlassCard(
        padding: const EdgeInsets.all(14),
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 20,
                color: Color(0xFF25D366),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Chat AYA',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cadife.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Duvidas? Fale com nossa assistente virtual',
                    style: TextStyle(
                      fontSize: 11,
                      color: cadife.textSecondary,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: cadife.textSecondary.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
