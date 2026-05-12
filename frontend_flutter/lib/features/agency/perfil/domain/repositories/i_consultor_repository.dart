import 'dart:typed_data';

import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/perfil/domain/entities/consultor_profile_models.dart';
import 'package:fpdart/fpdart.dart';

abstract class IConsultorRepository {
  Future<Either<Failure, ConsultorProfile>> getProfile();
  Future<Either<Failure, ConsultorProfile>> updateBio(String bio);
  Future<Either<Failure, List<SaleGoal>>> getGoals();
  Future<Either<Failure, ConsultantMetrics>> getMetrics();
  Future<Either<Failure, ConsultorProfile>> uploadPhoto(
    Uint8List bytes,
    String fileName,
  );
}
