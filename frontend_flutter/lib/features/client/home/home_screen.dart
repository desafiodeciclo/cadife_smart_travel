import 'package:cadife_smart_travel/core/theme/app_colors.dart';
import 'package:cadife_smart_travel/features/auth/providers/auth_provider.dart';
import 'package:cadife_smart_travel/features/client/home/widgets/consultant_card.dart';
import 'package:cadife_smart_travel/features/client/home/widgets/documents_section.dart';
import 'package:cadife_smart_travel/features/client/home/widgets/ongoing_trip_card.dart';
import 'package:cadife_smart_travel/features/client/home/widgets/status_stepper_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(authProvider).valueOrNull?.user?.name ?? 'Viajante';

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _CadifeAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GreetingSection(userName: userName),
                const SizedBox(height: 12),
                const StatusStepperWidget(currentStep: 2),
                const SizedBox(height: 20),
                const OngoingTripCard(
                  destination: 'Paris, França',
                  date: '15 Out 2024',
                  time: '20:45',
                ),
                const SizedBox(height: 24),
                const ConsultantCard(),
                const SizedBox(height: 24),
                const DocumentsSection(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CadifeAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.primary,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: CircleAvatar(
          backgroundColor: Colors.white.withValues(alpha: 0.25),
          child: const Icon(Icons.person, color: Colors.white, size: 20),
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
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {},
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Olá, $userName!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sua próxima aventura começa em breve.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
