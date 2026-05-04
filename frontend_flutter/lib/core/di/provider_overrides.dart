import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:cadife_smart_travel/features/agency/agenda/domain/repositories/agenda_port.dart';
import 'package:cadife_smart_travel/features/agency/agenda/presentation/providers/agenda_provider.dart' as agency_agenda;
import 'package:cadife_smart_travel/features/agency/proposals/domain/repositories/proposal_port.dart';
import 'package:cadife_smart_travel/features/agency/proposals/proposals_provider.dart' as agency_proposals;
import 'package:cadife_smart_travel/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:cadife_smart_travel/features/client/profile/domain/repositories/profile_port.dart';
import 'package:cadife_smart_travel/features/client/profile/profile_provider.dart' as client_profile;
import 'package:flutter_riverpod/flutter_riverpod.dart';

List<Override> getProviderOverrides() {
  return [
    authRepositoryProvider.overrideWithValue(sl<IAuthRepository>()),
    // Leads agora usa Riverpod DI diretamente (leadsRepositoryProvider)
    agency_agenda.agendaPortProvider.overrideWithValue(sl<AgendaPort>()),
    agency_proposals.proposalPortProvider.overrideWithValue(sl<ProposalPort>()),
    client_profile.profilePortProvider.overrideWithValue(sl<ProfilePort>()),
  ];
}
