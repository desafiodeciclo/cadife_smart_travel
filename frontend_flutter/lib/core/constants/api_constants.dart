import 'package:cadife_smart_travel/config/app_config.dart';
import 'package:get_it/get_it.dart';

/// Constantes de API — URLs e paths dos endpoints.
class ApiConstants {
  ApiConstants._();

  // ── Base URL ───────────────────────────────────────────
  // Recupera a URL base dinamicamente do AppConfig registrado no Service Locator.
  static String get baseUrl => GetIt.I<AppConfig>().apiBaseUrl;

  // Para testar no celular físico via USB, use o IP da máquina (WiFi)
  // Substitua pelo seu IP local: ipconfig → Endereço IPv4
  static const String baseUrlDev = 'http://192.168.1.113:8080';
  static const String baseUrlStaging = 'https://api-staging.cadife.com';
  static const String baseUrlProd = 'https://api.cadife.com';

  // ── Auth ───────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String registerFcmToken = '/users/fcm-token';
  static const String me = '/users/me';
  static const String forgotPassword = '/auth/forgot-password';
  static const String changePassword = '/auth/change-password';
  static const String resetPassword = '/auth/reset-password';
  static const String logoutAllDevices = '/auth/logout-all-devices';

  // ── Leads ──────────────────────────────────────────────
  static const String leads = '/leads';
  static String leadById(String id) => '/leads/$id';
  static String leadBriefing(String id) => '/leads/$id/briefing';
  static String leadAyaToggle(String id) => '/leads/$id/aya-toggle';
  static String leadReassign(String id) => '/leads/$id/reassign';
  static const String leadsManual = '/leads/manual';

  // ── Agenda ─────────────────────────────────────────────
  static const String agenda = '/agenda';
  static String agendaById(String id) => '/agenda/$id';

  // ── Propostas ──────────────────────────────────────────
  static const String proposals = '/propostas';
  static String proposalById(String id) => '/propostas/$id';
  static String proposalSend(String id) => '/propostas/$id/enviar';
  static String proposalVersions(String id) => '/propostas/$id/versoes';

  // ── Itinerário ─────────────────────────────────────────
  static String leadItinerary(String id) => '/leads/$id/itinerary';
  static String leadNote(String id, String date) => '/leads/$id/notes/$date';

  // ── Checkpoints ────────────────────────────────────────
  static String leadCheckpoints(String id) => '/leads/$id/checkpoints';

  // ── Conversation Summaries ─────────────────────────────
  static String leadConversationSummary(String id) => '/leads/$id/conversation-summary';
  static String leadConversationSummaries(String id) => '/leads/$id/conversation-summaries';

  // ── IA ─────────────────────────────────────────────────
  static const String iaProcessar = '/ia/processar';
  static const String iaExtrairBriefing = '/ia/extrair-briefing';

  // ── Travels ────────────────────────────────────────────
  static String travelDocuments(String travelId) => '/travels/$travelId/documents';

  // ── Webhook (para health check) ────────────────────────
  static const String webhookHealth = '/health';
}
