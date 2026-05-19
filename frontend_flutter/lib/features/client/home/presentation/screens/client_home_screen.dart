import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/home/presentation/providers/client_home_providers.dart';
import 'package:cadife_smart_travel/features/client/presentation/widgets/consultant_contact_card.dart';
import 'package:cadife_smart_travel/features/client/presentation/widgets/current_trip_banner.dart';
import 'package:cadife_smart_travel/features/client/presentation/widgets/documents_section.dart';
import 'package:cadife_smart_travel/features/client/presentation/widgets/itinerary_preview_section.dart';
import 'package:cadife_smart_travel/features/client/presentation/widgets/recommendations_section.dart';
import 'package:cadife_smart_travel/features/client/presentation/widgets/trip_status_section.dart';
import 'package:cadife_smart_travel/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:cadife_smart_travel/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClientHomeScreen extends ConsumerWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final tripAsync = ref.watch(currentClientTripProvider);
    final consultantAsync = ref.watch(clientConsultantProvider);
    final documentsAsync = ref.watch(clientHomeDocumentsProvider);
    final recommendationsAsync = ref.watch(clientRecommendationsProvider);

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
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentClientTripProvider);
          ref.invalidate(clientConsultantProvider);
          ref.invalidate(clientHomeDocumentsProvider);
          ref.invalidate(clientRecommendationsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 0. Saudação ao usuário
                userAsync.when(
                  data: (user) {
                    if (user == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        'Olá, ${user.name}',
                        style: AppTextStyles.h2.copyWith(
                          color: context.cadife.textPrimary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: ShimmerLoading(
                      isLoading: true,
                      child: Skeleton(height: 32, width: 200),
                    ),
                  ),
                  error: (err, _) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      'Erro ao carregar nome: $err',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ),

                // 1 & 2. Banner + status da viagem atual
                tripAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => _SectionError(
                    message: 'Erro ao carregar viagem: $err',
                  ),
                  data: (trip) {
                    if (trip == null) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('Nenhuma viagem ativa no momento.'),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CurrentTripBanner(trip: trip),
                        const SizedBox(height: 24),
                        TripStatusSection(trip: trip),
                        const SizedBox(height: 24),
                        ItineraryPreviewSection(tripId: trip.id),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),

                // 3. Documentos
                documentsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (err, _) =>
                      _SectionError(message: 'Erro nos documentos: $err'),
                  data: (documents) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DocumentsSection(documents: documents),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // 5. Consultor
                consultantAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (err, _) => const SizedBox.shrink(),
                  data: (consultant) {
                    if (consultant == null) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ConsultantContactCard(consultant: consultant),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),

                // 6. Ofertas baseadas no perfil
                recommendationsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (err, _) =>
                      _SectionError(message: 'Erro nas ofertas: $err'),
                  data: (recommendations) => RecommendationsSection(
                    recommendations: recommendations,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        message,
        style: const TextStyle(color: Colors.red, fontSize: 12),
      ),
    );
  }
}
