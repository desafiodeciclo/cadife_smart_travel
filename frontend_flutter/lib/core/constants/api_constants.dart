/// Constantes de API — URLs e paths dos endpoints.
class ApiConstants {
  ApiConstants._();

  // ── Base URL ───────────────────────────────────────────
  // Set at build time via --dart-define=BASE_URL=<url>
  // flutter run                                     → dev (default)
  // flutter run --dart-define=BASE_URL=<stagingUrl> → staging
  // flutter build apk --dart-define=BASE_URL=<prodUrl> → production
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:8000', // emulador Android → localhost
  );

  static const String baseUrlDev = 'http://10.0.2.2:8000';
  static const String baseUrlStaging = 'https://api-staging.cadife.com';
  static const String baseUrlProd = 'https://api.cadife.com';

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
