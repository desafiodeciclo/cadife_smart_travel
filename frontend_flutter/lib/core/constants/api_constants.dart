/// Constantes de API — URLs e paths dos endpoints.
class ApiConstants {
  ApiConstants._();

  // ── Base URL ───────────────────────────────────────────
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:8000', // emulador Android → localhost
  );

  // ── Auth ───────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String registerFcmToken = '/users/fcm-token';

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
