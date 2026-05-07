import 'package:equatable/equatable.dart';

class ClientSettings extends Equatable {
  const ClientSettings({
    required this.name,
    required this.email,
    required this.phone,
    this.dateOfBirth,
    this.notificationsPushOffers = true,
    this.notificationsPushTripsUpdates = true,
    this.notificationsPushAya = true,
    this.notificationsInAppOffers = true,
    this.notificationsInAppTripsUpdates = true,
    this.notificationsInAppAya = true,
    this.dndEnabled = false,
    this.dndStartTime = '22:00',
    this.dndEndTime = '08:00',
  });

  final String name;
  final String email;

  // Raw digits: "11999887766"
  final String phone;
  final DateTime? dateOfBirth;

  // Push notifications
  final bool notificationsPushOffers;
  final bool notificationsPushTripsUpdates;
  final bool notificationsPushAya;

  // In-app notifications
  final bool notificationsInAppOffers;
  final bool notificationsInAppTripsUpdates;
  final bool notificationsInAppAya;

  // Do Not Disturb
  final bool dndEnabled;
  final String dndStartTime; // "HH:mm"
  final String dndEndTime;   // "HH:mm"

  ClientSettings copyWith({
    String? name,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    bool clearDateOfBirth = false,
    bool? notificationsPushOffers,
    bool? notificationsPushTripsUpdates,
    bool? notificationsPushAya,
    bool? notificationsInAppOffers,
    bool? notificationsInAppTripsUpdates,
    bool? notificationsInAppAya,
    bool? dndEnabled,
    String? dndStartTime,
    String? dndEndTime,
  }) =>
      ClientSettings(
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        dateOfBirth:
            clearDateOfBirth ? null : (dateOfBirth ?? this.dateOfBirth),
        notificationsPushOffers:
            notificationsPushOffers ?? this.notificationsPushOffers,
        notificationsPushTripsUpdates:
            notificationsPushTripsUpdates ?? this.notificationsPushTripsUpdates,
        notificationsPushAya: notificationsPushAya ?? this.notificationsPushAya,
        notificationsInAppOffers:
            notificationsInAppOffers ?? this.notificationsInAppOffers,
        notificationsInAppTripsUpdates: notificationsInAppTripsUpdates ??
            this.notificationsInAppTripsUpdates,
        notificationsInAppAya:
            notificationsInAppAya ?? this.notificationsInAppAya,
        dndEnabled: dndEnabled ?? this.dndEnabled,
        dndStartTime: dndStartTime ?? this.dndStartTime,
        dndEndTime: dndEndTime ?? this.dndEndTime,
      );

  @override
  List<Object?> get props => [
        name,
        email,
        phone,
        dateOfBirth,
        notificationsPushOffers,
        notificationsPushTripsUpdates,
        notificationsPushAya,
        notificationsInAppOffers,
        notificationsInAppTripsUpdates,
        notificationsInAppAya,
        dndEnabled,
        dndStartTime,
        dndEndTime,
      ];
}
