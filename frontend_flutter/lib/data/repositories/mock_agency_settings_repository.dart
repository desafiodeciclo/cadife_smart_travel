import 'package:cadife_smart_travel/core/ports/agency_settings_port.dart';
import 'package:cadife_smart_travel/features/agency/settings/settings_models.dart';

class MockAgencySettingsRepository implements AgencySettingsPort {
  int _idCounter = 3;

  AgencySettings _settings = const AgencySettings(
    officeHours: [
      OfficeHours(weekday: 1, isOpen: true, openTime: '08:00', closeTime: '18:00'),
      OfficeHours(weekday: 2, isOpen: true, openTime: '08:00', closeTime: '18:00'),
      OfficeHours(weekday: 3, isOpen: true, openTime: '08:00', closeTime: '18:00'),
      OfficeHours(weekday: 4, isOpen: true, openTime: '08:00', closeTime: '18:00'),
      OfficeHours(weekday: 5, isOpen: true, openTime: '08:00', closeTime: '18:00'),
      OfficeHours(weekday: 6, isOpen: false, openTime: '09:00', closeTime: '13:00'),
      OfficeHours(weekday: 7, isOpen: false, openTime: '09:00', closeTime: '13:00'),
    ],
    notifications: NotificationPrefs(newLeads: true, qualifiedLeads: true),
    templates: [
      MessageTemplate(
        id: 'tpl-001',
        title: 'Boas-vindas',
        body: 'Olá! Sou consultor da Cadife Tour e estou aqui para ajudar com sua viagem. Quando podemos conversar?',
      ),
      MessageTemplate(
        id: 'tpl-002',
        title: 'Proposta enviada',
        body: 'Sua proposta personalizada foi enviada. Fique à vontade para tirar dúvidas!',
      ),
    ],
  );

  @override
  Future<AgencySettings> getSettings() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _settings;
  }

  @override
  Future<AgencySettings> updateSettings(AgencySettings settings) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _settings = settings;
    return _settings;
  }

  String nextTemplateId() => 'tpl-${_idCounter++}';
}
