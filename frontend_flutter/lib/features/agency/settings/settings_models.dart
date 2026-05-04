import 'package:equatable/equatable.dart';

class OfficeHours extends Equatable {
  const OfficeHours({
    required this.weekday,
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
  });

  // 1=Mon … 7=Sun (ISO weekday)
  final int weekday;
  final bool isOpen;
  final String openTime;
  final String closeTime;

  OfficeHours copyWith({bool? isOpen, String? openTime, String? closeTime}) =>
      OfficeHours(
        weekday: weekday,
        isOpen: isOpen ?? this.isOpen,
        openTime: openTime ?? this.openTime,
        closeTime: closeTime ?? this.closeTime,
      );

  String get weekdayLabel => const [
        '',
        'Segunda',
        'Terça',
        'Quarta',
        'Quinta',
        'Sexta',
        'Sábado',
        'Domingo',
      ][weekday];

  @override
  List<Object?> get props => [weekday, isOpen, openTime, closeTime];
}

class NotificationPrefs extends Equatable {
  const NotificationPrefs({
    required this.newLeads,
    required this.qualifiedLeads,
  });

  final bool newLeads;
  final bool qualifiedLeads;

  NotificationPrefs copyWith({bool? newLeads, bool? qualifiedLeads}) =>
      NotificationPrefs(
        newLeads: newLeads ?? this.newLeads,
        qualifiedLeads: qualifiedLeads ?? this.qualifiedLeads,
      );

  @override
  List<Object?> get props => [newLeads, qualifiedLeads];
}

class MessageTemplate extends Equatable {
  const MessageTemplate({required this.id, required this.title, required this.body});

  final String id;
  final String title;
  final String body;

  @override
  List<Object?> get props => [id, title, body];
}

class AgencySettings extends Equatable {
  const AgencySettings({
    required this.officeHours,
    required this.notifications,
    required this.templates,
  });

  final List<OfficeHours> officeHours;
  final NotificationPrefs notifications;
  final List<MessageTemplate> templates;

  AgencySettings copyWith({
    List<OfficeHours>? officeHours,
    NotificationPrefs? notifications,
    List<MessageTemplate>? templates,
  }) =>
      AgencySettings(
        officeHours: officeHours ?? this.officeHours,
        notifications: notifications ?? this.notifications,
        templates: templates ?? this.templates,
      );

  @override
  List<Object?> get props => [officeHours, notifications, templates];
}
