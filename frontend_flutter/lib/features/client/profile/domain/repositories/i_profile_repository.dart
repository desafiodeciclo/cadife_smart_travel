import 'package:fpdart/fpdart.dart';
import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';

abstract class IProfileRepository {
  Future<Either<Failure, AuthUser>> getCurrentUser();
  Future<Either<Failure, AuthUser>> updateProfile({
    String? name,
    List<String>? tipoViagem,
    List<String>? preferencias,
    bool? temPassaporte,
  });
}
