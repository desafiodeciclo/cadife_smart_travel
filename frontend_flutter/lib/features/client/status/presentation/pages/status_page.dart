import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/status/presentation/widgets/ongoing_trip_card.dart';
import 'package:cadife_smart_travel/features/client/status/presentation/widgets/status_stepper_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatusPage extends ConsumerWidget {
  const StatusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cadife = context.cadife;

    return PageScaffold(
      title: 'MINHA VIAGEM',
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 72, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OngoingTripCard(),
              const SizedBox(height: 32),
              Text(
                'Sua Jornada',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: cadife.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              const StatusStepperWidget(currentStep: 1),
            ],
          ),
        ),
      ),
    );
  }
}
