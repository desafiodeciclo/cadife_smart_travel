import 'package:equatable/equatable.dart';

class OfficeHours extends Equatable {
  const OfficeHours({
    required this.weekday,
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
  });

  // 1=Mon … 5=Fri (ISO weekday; UI only shows 1–5)
  final int weekday;
  final bool isOpen;
  final String openTime;  // "09:00"
  final String closeTime; // "16:00"

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
    this.schedulingConfirmed = true,
    this.inactiveLeadDays,
  });

  final bool newLeads;
  final bool qualifiedLeads;
  final bool schedulingConfirmed;
  // null = desativado; 3,5,7,10,14 = ativo com N dias de inatividade
  final int? inactiveLeadDays;

  NotificationPrefs copyWith({
    bool? newLeads,
    bool? qualifiedLeads,
    bool? schedulingConfirmed,
    int? inactiveLeadDays,
    bool clearInactiveDays = false,
  }) =>
      NotificationPrefs(
        newLeads: newLeads ?? this.newLeads,
        qualifiedLeads: qualifiedLeads ?? this.qualifiedLeads,
        schedulingConfirmed: schedulingConfirmed ?? this.schedulingConfirmed,
        inactiveLeadDays: clearInactiveDays
            ? null
            : (inactiveLeadDays ?? this.inactiveLeadDays),
      );

  @override
  List<Object?> get props =>
      [newLeads, qualifiedLeads, schedulingConfirmed, inactiveLeadDays];
}

class MessageTemplate extends Equatable {
  const MessageTemplate({
    required this.id,
    required this.title,
    required this.body,
  });

  final String id;
  final String title;
  final String body;

  MessageTemplate copyWith({String? title, String? body}) => MessageTemplate(
        id: id,
        title: title ?? this.title,
        body: body ?? this.body,
      );

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
