import 'package:fpdart/fpdart.dart';
import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/profile/consultor_profile_models.dart';

abstract class IConsultorRepository {
  Future<Either<Failure, ConsultorProfile>> getProfile();
  Future<Either<Failure, ConsultorProfile>> updateBio(String bio);
  Future<Either<Failure, List<SaleGoal>>> getGoals();
}
