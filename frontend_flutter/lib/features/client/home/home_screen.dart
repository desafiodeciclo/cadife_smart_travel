import 'package:cadife_smart_travel/core/theme/app_colors.dart';
import 'package:cadife_smart_travel/features/auth/providers/auth_provider.dart';
import 'package:cadife_smart_travel/features/client/home/providers/home_provider.dart';
import 'package:cadife_smart_travel/features/client/home/widgets/consultant_card.dart';
import 'package:cadife_smart_travel/features/client/home/widgets/documents_section.dart';
import 'package:cadife_smart_travel/features/client/home/widgets/ongoing_trip_card.dart';
import 'package:cadife_smart_travel/features/client/home/widgets/status_stepper_widget.dart';
import 'package:cadife_smart_travel/shared/models/models.dart';
import 'package:cadife_smart_travel/features/client/home/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  int _mapLeadStatusToStep(LeadStatus status) {
    switch (status) {
      case LeadStatus.novo:
      case LeadStatus.emAtendimento:
      case LeadStatus.qualificado:
      case LeadStatus.agendado:
        return 0;
      case LeadStatus.proposta:
        return 1;
      case LeadStatus.fechado:
        return 2;
      default:
        return 0;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'A definir';
    return DateFormat('dd MMM yyyy', 'pt_BR').format(date);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userName = authState.valueOrNull?.user?.name ?? 'Viajante';
    final activeLeadAsync = ref.watch(activeLeadProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const _CadifeAppBar(),
          SliverToBoxAdapter(
            child: activeLeadAsync.when(
              loading: () => const _HomeLoadingState(),
              error: (err, stack) => Center(child: Text('Erro ao carregar dados: $err')),
              data: (lead) {
                final currentStep = lead != null ? _mapLeadStatusToStep(lead.status) : 0;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GreetingSection(userName: userName),
                    const SizedBox(height: 12),
                    StatusStepperWidget(currentStep: currentStep),
                    const SizedBox(height: 20),
                    OngoingTripCard(
                      destination: lead?.destino ?? 'Próxima aventura',
                      date: _formatDate(lead?.dataIda),
                      time: lead?.dataIda != null ? DateFormat('HH:mm').format(lead!.dataIda!) : '--:--',
                      imageUrl: null, // Pode ser expandido futuramente
                    ),
                    const SizedBox(height: 24),
                    ConsultantCard(
                      consultantName: lead?.consultorNome ?? 'Ricardo Silva',
                      avatarUrl: lead?.consultorAvatar,
                    ),
                    const SizedBox(height: 24),
                    DocumentsSection(documents: ref.watch(clientDocumentsProvider)),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeLoadingState extends StatelessWidget {
  const _HomeLoadingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircularProgressIndicator(color: Theme.of(context).primaryColor),
          const SizedBox(height: 20),
          const Text('Carregando sua viagem...'),
        ],
      ),
    );
  }
}
class _CadifeAppBar extends ConsumerWidget {
  const _CadifeAppBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.primary,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => context.go('/client/perfil'),
          child: CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ),
      ),
      title: const Text(
        'CADIFE TOUR',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 17,
          letterSpacing: 2.5,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Badge(
            isLabelVisible: notifications.isNotEmpty,
            backgroundColor: Colors.red,
            smallSize: 10,
            child: PopupMenuButton<String>(
              tooltip: '',
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              offset: const Offset(0, 45),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              itemBuilder: (context) {
                if (notifications.isEmpty) {
                  return [
                    const PopupMenuItem<String>(
                      enabled: false,
                      child: Text(
                        'Sem notificações',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ];
                }
                return notifications.map((n) {
                  return PopupMenuItem<String>(
                    value: n.id,
                    child: Text(n.title),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _GreetingSection extends StatelessWidget {
  const _GreetingSection({required this.userName});
  final String userName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Olá, $userName!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sua próxima aventura começa em breve.',
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
