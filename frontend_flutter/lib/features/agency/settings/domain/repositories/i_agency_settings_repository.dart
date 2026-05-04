import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/settings/domain/entities/agency_settings.dart';
import 'package:fpdart/fpdart.dart';

abstract class IAgencySettingsRepository {
  Future<Either<Failure, AgencySettings>> getSettings();
  Future<Either<Failure, AgencySettings>> updateSettings(AgencySettings settings);
}
