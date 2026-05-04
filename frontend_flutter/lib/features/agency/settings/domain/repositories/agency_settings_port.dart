import 'package:cadife_smart_travel/features/agency/settings/settings_models.dart';

abstract class AgencySettingsPort {
  Future<AgencySettings> getSettings();
  Future<AgencySettings> updateSettings(AgencySettings settings);
}
