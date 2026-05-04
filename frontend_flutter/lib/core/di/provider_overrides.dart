import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:cadife_smart_travel/features/agency/agenda/agenda_provider.dart' as agency_agenda;
import 'package:cadife_smart_travel/features/agency/agenda/domain/repositories/agenda_port.dart';
import 'package:cadife_smart_travel/features/agency/dashboard/dashboard_provider.dart' as agency_dash;
import 'package:cadife_smart_travel/features/agency/lead_detail/lead_detail_provider.dart' as agency_detail;
import 'package:cadife_smart_travel/features/agency/leads/domain/repositories/lead_port.dart';
import 'package:cadife_smart_travel/features/agency/leads/leads_provider.dart' as agency_leads;
import 'package:cadife_smart_travel/features/agency/proposals/domain/repositories/proposal_port.dart';
import 'package:cadife_smart_travel/features/agency/proposals/proposals_provider.dart' as agency_proposals;
import 'package:cadife_smart_travel/features/auth/domain/repositories/auth_port.dart';
import 'package:cadife_smart_travel/features/auth/providers/auth_provider.dart';
import 'package:cadife_smart_travel/features/client/interactions/interactions_provider.dart' as client_interactions;
import 'package:cadife_smart_travel/features/client/profile/domain/repositories/profile_port.dart';
import 'package:cadife_smart_travel/features/client/profile/profile_provider.dart' as client_profile;
import 'package:cadife_smart_travel/features/client/trip_status/trip_status_provider.dart' as client_trip;
import 'package:flutter_riverpod/flutter_riverpod.dart';

List<Override> getProviderOverrides() {
  return [
    authPortProvider.overrideWithValue(sl<AuthPort>()),
    agency_dash.dashboardLeadPortProvider.overrideWithValue(sl<LeadPort>()),
    agency_leads.leadPortProvider.overrideWithValue(sl<LeadPort>()),
    agency_detail.leadPortProvider.overrideWithValue(sl<LeadPort>()),
    agency_agenda.agendaPortProvider.overrideWithValue(sl<AgendaPort>()),
    agency_proposals.proposalPortProvider.overrideWithValue(sl<ProposalPort>()),
    client_trip.clientLeadPortProvider.overrideWithValue(sl<LeadPort>()),
    client_interactions.interactionsPortProvider.overrideWithValue(sl<LeadPort>()),
    client_profile.profilePortProvider.overrideWithValue(sl<ProfilePort>()),
  ];
}
