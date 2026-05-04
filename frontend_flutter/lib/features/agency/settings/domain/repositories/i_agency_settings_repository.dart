import 'package:fpdart/fpdart.dart';
import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/settings/settings_models.dart';

abstract class IAgencySettingsRepository {
  Future<Either<Failure, AgencySettings>> getSettings();
  Future<Either<Failure, AgencySettings>> updateSettings(AgencySettings settings);
}
