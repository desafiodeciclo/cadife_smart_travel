import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:cadife_smart_travel/features/agency/agenda/domain/repositories/i_agenda_repository.dart';
import 'package:cadife_smart_travel/features/agency/agenda/presentation/providers/agenda_provider.dart' as agency_agenda;
import 'package:cadife_smart_travel/features/agency/perfil/domain/repositories/i_consultor_repository.dart';
import 'package:cadife_smart_travel/features/agency/perfil/presentation/providers/profile_notifier.dart' as agency_profile;
import 'package:cadife_smart_travel/features/agency/propostas/domain/repositories/i_proposals_repository.dart';
import 'package:cadife_smart_travel/features/agency/propostas/presentation/providers/proposals_provider.dart' as agency_proposals;
import 'package:cadife_smart_travel/features/agency/settings/domain/repositories/i_agency_settings_repository.dart';
import 'package:cadife_smart_travel/features/agency/settings/presentation/providers/settings_notifier.dart' as agency_settings;
import 'package:cadife_smart_travel/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:cadife_smart_travel/features/client/profile/domain/repositories/i_profile_repository.dart';
import 'package:cadife_smart_travel/features/client/profile/presentation/providers/profile_provider.dart' as client_profile;
import 'package:flutter_riverpod/flutter_riverpod.dart';

List<Override> getProviderOverrides() {
  return [
    authRepositoryProvider.overrideWithValue(sl<IAuthRepository>()),
    // Leads agora usa Riverpod DI diretamente (leadsRepositoryProvider)
    agency_agenda.agendaRepositoryProvider.overrideWithValue(sl<IAgendaRepository>()),
    agency_proposals.iProposalsRepositoryProvider.overrideWithValue(sl<IProposalsRepository>()),
    client_profile.iProfileRepositoryProvider.overrideWithValue(sl<IProfileRepository>()),
    agency_profile.iConsultorRepositoryProvider.overrideWithValue(sl<IConsultorRepository>()),
    agency_settings.iAgencySettingsRepositoryProvider.overrideWithValue(sl<IAgencySettingsRepository>()),
  ];
}
