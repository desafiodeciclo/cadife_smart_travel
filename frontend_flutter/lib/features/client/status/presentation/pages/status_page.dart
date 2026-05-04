import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/status/presentation/widgets/ongoing_trip_card.dart';
import 'package:cadife_smart_travel/features/client/status/presentation/widgets/status_stepper_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatusPage extends ConsumerWidget {
  const StatusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OngoingTripCard(),
                  SizedBox(height: 32),
                  Text(
                    'Sua Jornada',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 20),
                  StatusStepperWidget(currentStep: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.scaffold,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: const Text(
          'Minha Viagem',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withValues(alpha: 0.05),
                AppColors.scaffold,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
