import 'package:cadife_smart_travel/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OfficeHours {
  // Index 0=seg, 1=ter, 2=qua, 3=qui, 4=sex, 5=sáb, 6=dom
  final List<bool> activeDays;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  const OfficeHours({
    required this.activeDays,
    required this.startTime,
    required this.endTime,
  });

  factory OfficeHours.defaults() => const OfficeHours(
    activeDays: [true, true, true, true, true, false, false],
    startTime: TimeOfDay(hour: 9, minute: 0),
    endTime: TimeOfDay(hour: 18, minute: 0),
  );

  factory OfficeHours.fromJson(Map<String, dynamic> json) {
    final days = (json['dias_ativos'] as List<dynamic>?)
            ?.map((e) => e as bool)
            .toList() ??
        [true, true, true, true, true, false, false];
    final start = json['hora_inicio'] as String? ?? '09:00';
    final end = json['hora_fim'] as String? ?? '18:00';

    return OfficeHours(
      activeDays: days,
      startTime: _parseTime(start),
      endTime: _parseTime(end),
    );
  }

  static TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'dias_ativos': activeDays,
    'hora_inicio':
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
    'hora_fim':
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
  };

  OfficeHours copyWith({
    List<bool>? activeDays,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) =>
      OfficeHours(
        activeDays: activeDays ?? this.activeDays,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
      );
}

class MessageTemplate {
  final String id;
  final String name;
  final String content;

  const MessageTemplate({
    required this.id,
    required this.name,
    required this.content,
  });

  factory MessageTemplate.fromJson(Map<String, dynamic> json) =>
      MessageTemplate(
        id: json['id'] as String,
        name: json['nome'] as String,
        content: json['conteudo'] as String,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': name,
    'conteudo': content,
  };

  MessageTemplate copyWith({String? name, String? content}) => MessageTemplate(
    id: id,
    name: name ?? this.name,
    content: content ?? this.content,
  );
}

class NotificationPrefs {
  final bool leadsQualificados;
  final bool novosLeads;

  const NotificationPrefs({
    required this.leadsQualificados,
    required this.novosLeads,
  });

  factory NotificationPrefs.defaults() => const NotificationPrefs(
    leadsQualificados: true,
    novosLeads: true,
  );

  factory NotificationPrefs.fromJson(Map<String, dynamic> json) =>
      NotificationPrefs(
        leadsQualificados: json['leads_qualificados'] as bool? ?? true,
        novosLeads: json['novos_leads'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
    'leads_qualificados': leadsQualificados,
    'novos_leads': novosLeads,
  };

  NotificationPrefs copyWith({
    bool? leadsQualificados,
    bool? novosLeads,
  }) =>
      NotificationPrefs(
        leadsQualificados: leadsQualificados ?? this.leadsQualificados,
        novosLeads: novosLeads ?? this.novosLeads,
      );
}

class AgencySettings {
  final OfficeHours officeHours;
  final List<MessageTemplate> messageTemplates;
  final NotificationPrefs notificationPrefs;

  const AgencySettings({
    required this.officeHours,
    required this.messageTemplates,
    required this.notificationPrefs,
  });

  factory AgencySettings.defaults() => AgencySettings(
    officeHours: OfficeHours.defaults(),
    messageTemplates: const [],
    notificationPrefs: NotificationPrefs.defaults(),
  );

  factory AgencySettings.fromJson(Map<String, dynamic> json) => AgencySettings(
    officeHours: OfficeHours.fromJson(
      json['horarios_atendimento'] as Map<String, dynamic>? ?? {},
    ),
    messageTemplates: (json['templates_mensagem'] as List<dynamic>? ?? [])
        .map((e) => MessageTemplate.fromJson(e as Map<String, dynamic>))
        .toList(),
    notificationPrefs: NotificationPrefs.fromJson(
      json['preferencias_notificacao'] as Map<String, dynamic>? ?? {},
    ),
  );

  Map<String, dynamic> toJson() => {
    'horarios_atendimento': officeHours.toJson(),
    'templates_mensagem': messageTemplates.map((t) => t.toJson()).toList(),
    'preferencias_notificacao': notificationPrefs.toJson(),
  };

  AgencySettings copyWith({
    OfficeHours? officeHours,
    List<MessageTemplate>? messageTemplates,
    NotificationPrefs? notificationPrefs,
  }) =>
      AgencySettings(
        officeHours: officeHours ?? this.officeHours,
        messageTemplates: messageTemplates ?? this.messageTemplates,
        notificationPrefs: notificationPrefs ?? this.notificationPrefs,
      );
}

class SettingsRepository {
  final ApiService _api;
  SettingsRepository(this._api);

  Future<AgencySettings> getSettings() async {
    final response = await _api.get('/agency/settings');
    return AgencySettings.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AgencySettings> saveSettings(AgencySettings settings) async {
    final response = await _api.put('/agency/settings', data: settings.toJson());
    return AgencySettings.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MessageTemplate> addTemplate(String name, String content) async {
    final response = await _api.post('/agency/settings/templates', data: {
      'nome': name,
      'conteudo': content,
    });
    return MessageTemplate.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteTemplate(String id) async {
    await _api.delete('/agency/settings/templates/$id');
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(apiServiceProvider));
});
