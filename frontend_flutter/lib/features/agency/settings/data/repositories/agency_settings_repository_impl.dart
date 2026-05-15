import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/settings/domain/entities/agency_settings.dart';
import 'package:cadife_smart_travel/features/agency/settings/domain/repositories/i_agency_settings_repository.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

class AgencySettingsRepositoryImpl implements IAgencySettingsRepository {
  AgencySettingsRepositoryImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<Either<Failure, AgencySettings>> getSettings() async {
    try {
      final res = await _dio.get('/agency/settings');
      return Right(_fromJson(res.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, AgencySettings>> updateSettings(
    AgencySettings settings,
  ) async {
    try {
      final res = await _dio.put(
        '/agency/settings',
        data: _toUpdatePayload(settings),
      );
      return Right(_fromJson(res.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  AgencySettings _fromJson(Map<String, dynamic> json) {
    final horario = json['horario_funcionamento'] as Map<String, dynamic>;
    final dias = (horario['dias'] as List<dynamic>).cast<int>().toSet();
    final inicio = horario['inicio'] as String;
    final fim = horario['fim'] as String;

    // Backend modela horário como bloco único (dias + inicio/fim).
    // Flutter modela como uma entrada por dia da semana (1=Seg…5=Sex).
    final officeHours = List.generate(5, (i) {
      final weekday = i + 1;
      return OfficeHours(
        weekday: weekday,
        isOpen: dias.contains(weekday),
        openTime: inicio,
        closeTime: fim,
      );
    });

    final prefs = json['notificacoes_prefs'] as Map<String, dynamic>;
    final notifications = NotificationPrefs(
      newLeads: prefs['novos_leads'] as bool? ?? true,
      qualifiedLeads: prefs['leads_qualificados'] as bool? ?? true,
      schedulingConfirmed: prefs['agendamentos_confirmados'] as bool? ?? true,
    );

    final templates = (json['templates'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .where((t) => t['ativo'] as bool? ?? true)
        .map(
          (t) => MessageTemplate(
            id: t['id'] as String,
            title: t['nome'] as String,
            body: t['conteudo'] as String,
          ),
        )
        .toList();

    return AgencySettings(
      officeHours: officeHours,
      notifications: notifications,
      templates: templates,
    );
  }

  Map<String, dynamic> _toUpdatePayload(AgencySettings settings) {
    final openDays = settings.officeHours.where((h) => h.isOpen).toList();
    return {
      'horario_funcionamento': {
        'dias': openDays.map((h) => h.weekday).toList(),
        'inicio': openDays.isNotEmpty ? openDays.first.openTime : '09:00',
        'fim': openDays.isNotEmpty ? openDays.first.closeTime : '18:00',
      },
      'notificacoes_prefs': {
        'novos_leads': settings.notifications.newLeads,
        'leads_qualificados': settings.notifications.qualifiedLeads,
        'agendamentos_confirmados': settings.notifications.schedulingConfirmed,
        'propostas_aprovadas': true,
      },
    };
  }
}
