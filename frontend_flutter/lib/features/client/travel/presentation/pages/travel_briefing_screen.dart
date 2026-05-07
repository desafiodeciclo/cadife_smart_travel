import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/travel/presentation/widgets/travel_briefing_tab.dart';
import 'package:flutter/material.dart';

class TravelBriefingScreen extends StatelessWidget {
  const TravelBriefingScreen({required this.leadId, super.key});

  final String leadId;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'DETALHES DA VIAGEM',
      showBackgroundEffects: false,
      body: TravelBriefingTab(leadId: leadId),
    );
  }
}
