import 'package:cadife_smart_travel/features/agency/leads/domain/repositories/i_leads_repository.dart';
import 'package:cadife_smart_travel/features/agency/propostas/domain/repositories/i_proposals_repository.dart';
import 'package:cadife_smart_travel/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:cadife_smart_travel/features/client/profile/domain/repositories/i_profile_repository.dart';
import 'package:mocktail/mocktail.dart';

/// Fakes de repositórios com Mocktail para uso em testes de unidade e widget.
class MockAuthRepository extends Mock implements IAuthRepository {}
class MockLeadsRepository extends Mock implements ILeadsRepository {}
class MockProposalsRepository extends Mock implements IProposalsRepository {}
class MockProfileRepository extends Mock implements IProfileRepository {}
