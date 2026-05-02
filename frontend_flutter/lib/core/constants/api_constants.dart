import 'package:cadife_smart_travel/core/config/env_config.dart';
import 'package:get_it/get_it.dart';

/// Constantes de API — URLs e paths dos endpoints.
class ApiConstants {
  ApiConstants._();

  // ── Base URL ───────────────────────────────────────────
  // Recupera a URL base dinamicamente do EnvConfig registrado no Service Locator.
  static String get baseUrl => GetIt.I<EnvConfig>().apiBaseUrl;

  static const String baseUrlDev = 'http://10.0.2.2:8000';
  static const String baseUrlStaging = 'https://api-staging.cadife.com';
  static const String baseUrlProd = 'https://api.cadife.com';

  // ── Auth ───────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String registerFcmToken = '/users/fcm-token';
  static const String me = '/users/me';

  // ── Leads ──────────────────────────────────────────────
  static const String leads = '/leads';
  static String leadById(String id) => '/leads/$id';
  static String leadBriefing(String id) => '/leads/$id/briefing';

  // ── Agenda ─────────────────────────────────────────────
  static const String agenda = '/agenda';
  static String agendaById(String id) => '/agenda/$id';

  // ── Propostas ──────────────────────────────────────────
  static const String proposals = '/propostas';
  static String proposalById(String id) => '/propostas/$id';

  // ── IA ─────────────────────────────────────────────────
  static const String iaProcessar = '/ia/processar';
  static const String iaExtrairBriefing = '/ia/extrair-briefing';

  // ── Webhook (para health check) ────────────────────────
  static const String webhookHealth = '/health';
}
