import 'package:cadife_smart_travel/features/client/settings/domain/entities/client_settings.dart';

class ClientSettingsMocks {
  const ClientSettingsMocks._();

  static ClientSettings mockSettings() => ClientSettings(
        name: 'Ana Silva',
        email: 'ana.silva@example.com',
        phone: '11999887766',
        dateOfBirth: DateTime(1990, 5, 15),
        notificationsPushOffers: true,
        notificationsPushTripsUpdates: true,
        notificationsPushAya: true,
        notificationsInAppOffers: false,
        notificationsInAppTripsUpdates: true,
        notificationsInAppAya: true,
        dndEnabled: false,
        dndStartTime: '22:00',
        dndEndTime: '08:00',
      );
}
