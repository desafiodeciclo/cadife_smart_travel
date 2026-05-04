import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/status/presentation/widgets/ongoing_trip_card.dart';
import 'package:cadife_smart_travel/features/client/status/presentation/widgets/status_stepper_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cadife = context.cadife;

    return SliverAppBar(
      expandedHeight: 80,
      pinned: true,
      backgroundColor: isDark ? AppColors.darkSurface : cadife.primary,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'MINHA VIAGEM',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 16,
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}
