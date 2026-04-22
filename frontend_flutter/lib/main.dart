import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:cadife_smart_travel/core/ports/agenda_port.dart';
import 'package:cadife_smart_travel/core/ports/auth_port.dart';
import 'package:cadife_smart_travel/core/ports/lead_port.dart';
import 'package:cadife_smart_travel/core/ports/proposal_port.dart';
import 'package:cadife_smart_travel/core/router/app_router.dart';
import 'package:cadife_smart_travel/core/theme/app_theme.dart';
import 'package:cadife_smart_travel/features/agency/agenda/agenda_provider.dart' as agency_agenda;
import 'package:cadife_smart_travel/features/agency/dashboard/dashboard_provider.dart' as agency_dash;
import 'package:cadife_smart_travel/features/agency/lead_detail/lead_detail_provider.dart' as agency_detail;
import 'package:cadife_smart_travel/features/agency/leads/leads_provider.dart' as agency_leads;
import 'package:cadife_smart_travel/features/agency/proposals/proposals_provider.dart' as agency_proposals;
import 'package:cadife_smart_travel/features/auth/auth_notifier.dart';
import 'package:cadife_smart_travel/features/auth/providers/auth_provider.dart';
import 'package:cadife_smart_travel/features/client/documents/documents_provider.dart' as client_docs;
import 'package:cadife_smart_travel/features/client/interactions/interactions_provider.dart' as client_interactions;
import 'package:cadife_smart_travel/features/client/profile/profile_provider.dart' as client_profile;
import 'package:cadife_smart_travel/features/client/trip_status/trip_status_provider.dart' as client_trip;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // late final allows the closure below to capture container by reference safely.
  // The callback is only invoked at 401 token expiry — always after runApp().
  late final ProviderContainer container;

  await setupServiceLocator(
    onTokenExpired: () => container.read(authProvider.notifier).logout(),
  );
  await initDependencies();

  container = ProviderContainer(
    overrides: [
      authPortProvider.overrideWithValue(sl<AuthPort>()),
      agency_dash.dashboardLeadPortProvider.overrideWithValue(sl<LeadPort>()),
      agency_leads.leadPortProvider.overrideWithValue(sl<LeadPort>()),
      agency_detail.leadPortProvider.overrideWithValue(sl<LeadPort>()),
      agency_agenda.agendaPortProvider.overrideWithValue(sl<AgendaPort>()),
      agency_proposals.proposalPortProvider.overrideWithValue(sl<ProposalPort>()),
      client_trip.clientLeadPortProvider.overrideWithValue(sl<LeadPort>()),
      client_interactions.interactionsPortProvider.overrideWithValue(sl<LeadPort>()),
      client_docs.documentsProvider.overrideWithValue(null),
      client_profile.profileAuthProvider.overrideWithValue(sl<AuthPort>()),
    ],
  );

  runApp(UncontrolledProviderScope(
    container: container,
    child: const CadifeApp(),
  ));
}

class CadifeApp extends ConsumerWidget {
  const CadifeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Cadife Smart Travel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
