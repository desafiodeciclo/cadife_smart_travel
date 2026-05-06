import 'package:cadife_smart_travel/features/agency/leads/presentation/widgets/lead_detail_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LeadDetailPage extends ConsumerWidget {
  final String leadId;
  const LeadDetailPage({required this.leadId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LeadDetailContent(leadId: leadId, showAppBar: true);
  }
}
