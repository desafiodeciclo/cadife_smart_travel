import 'package:fpdart/fpdart.dart';
import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/profile/consultor_profile_models.dart';
import 'package:cadife_smart_travel/features/agency/profile/domain/repositories/i_consultor_repository.dart';

class MockConsultorRepository implements IConsultorRepository {
  ConsultorProfile _profile = const ConsultorProfile(
    id: 'consultor-001',
    name: 'Jakeline Ferreira',
    email: 'jakeline@cadifetravel.com.br',
    bio: 'Especialista em viagens internacionais e cruzeiros há 8 anos. '
        'Apaixonada por criar experiências únicas para cada cliente.',
    phone: '+55 11 99876-5432',
    avatarUrl: null,
    totalSales: 142,
    conversionRate: 0.68,
    activeMonths: 38,
  );

  @override
  Future<Either<Failure, ConsultorProfile>> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return Right(_profile);
  }

  @override
  Future<Either<Failure, ConsultorProfile>> updateBio(String bio) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _profile = _profile.copyWith(bio: bio);
    return Right(_profile);
  }

  @override
  Future<Either<Failure, List<SaleGoal>>> getGoals() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final now = DateTime.now();
    return Right([
      SaleGoal(month: now.month, year: now.year, target: 12, achieved: 8),
      SaleGoal(
          month: now.month - 1 <= 0 ? 12 : now.month - 1,
          year: now.month - 1 <= 0 ? now.year - 1 : now.year,
          target: 10,
          achieved: 10),
      SaleGoal(
          month: now.month - 2 <= 0 ? 12 + (now.month - 2) : now.month - 2,
          year: now.month - 2 <= 0 ? now.year - 1 : now.year,
          target: 10,
          achieved: 7),
      SaleGoal(
          month: now.month - 3 <= 0 ? 12 + (now.month - 3) : now.month - 3,
          year: now.month - 3 <= 0 ? now.year - 1 : now.year,
          target: 8,
          achieved: 9),
    ]);
  }
}
